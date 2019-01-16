defmodule Mix.Tasks.Veil.Add do
  use Mix.Task
  require IEx

  @shortdoc "Add simple passwordless authentication using Veil to your Phoenix app"

  @moduledoc """
  Veil - simple passwordless authentication for your Phoenix apps.

  This installer will do the following:
  * Append the :veil configuration to your `config/config.exs` file.
  * Generate the Veil.User, Veil.Request and Veil.Session schemas in `lib/yourapp/veil/`
  * Generate an Ecto migration for these schemas in `priv/repo/migrations/`
  * Generate controllers, views, plugs and templates in `lib/yourapp_web/[type]/veil`
  * If this is a new phoenix app using the default template, modify it to include a sign in link

  ## Examples

      # Default installation
      mix veil.add
  """

  def run(_args) do
    Mix.shell().info([:cyan, "\nAdding Veil to your project...\n"])

    config()
    |> verify_paths()
    |> append_config_file()
    |> copy_main_dir()
    |> copy_web_dir()
    |> copy_templates()
    |> copy_migration()
    |> amend_default_template()
    |> amend_router()
    |> show_final_instructions()
  end

  @doc """
  Set up the config map
  """
  def config do
    %{}
    |> config_names()
    |> config_paths()
    |> config_secrets()
    |> config_html?()
  end

  @doc """
  Add the app name to config
  """
  def config_names(config) do
    inflected =
      Mix.Phoenix.otp_app()
      |> to_string()
      |> Mix.Phoenix.inflect()

    config
    |> Map.put(:path, inflected[:path])
    |> Map.put(:main_module, inflected[:base])
    |> Map.put(:web_module, inflected[:web_module])
  end

  @doc """
  Add the main paths of the application to config
  """
  def config_paths(config) do
    web_path = Path.join(["lib", config[:path] <> "_web"])
    main_path = Path.join(["lib", config[:path]])
    config_path = Path.join(["config", "config.exs"])
    migration_path = Path.join(["priv", "repo", "migrations", "#{timestamp()}_add_veil.exs"])
    layout_path = Path.join([web_path, "templates", "layout", "app.html.eex"])
    router_path = Path.join([web_path, "router.ex"])

    config
    |> Map.put(:main_path, main_path)
    |> Map.put(:web_path, web_path)
    |> Map.put(:config_path, config_path)
    |> Map.put(:migration_path, migration_path)
    |> Map.put(:layout_path, layout_path)
    |> Map.put(:router_path, router_path)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  @doc """
  Adds salts for the request/session internal tokens. These should only ever be saved in the
  database, so do not actually need to be this random.
  """
  def config_secrets(config) do
    config
    |> Map.put(:request_salt, random_salt())
    |> Map.put(:session_salt, random_salt())
  end

  defp random_salt do
    :crypto.strong_rand_bytes(23 + :rand.uniform(17))
    |> Base.encode64()
  end

  def config_html?(%{web_path: web_path} = config) do
    template_path = Path.join(web_path, "templates")

    case File.lstat(template_path) do
      {:ok, %{type: :directory}} ->
        Map.put(config, :html?, true)

      _ ->
        Map.put(config, :html?, false)
    end
  end

  @doc """
  Verify the paths all exist
  """
  def verify_paths(config) do
    %{main_path: main_path, web_path: web_path, config_path: config_path} = config

    with {:ok, %{type: :directory}} <- File.lstat(main_path),
         {:ok, %{type: :directory}} <- File.lstat(web_path),
         {:ok, %{type: :regular}} <- File.lstat(config_path) do
      config
    else
      _ ->
        Mix.raise("Cannot find all paths: #{main_path}, #{web_path}, #{config_path}")
    end
  end

  @doc """
  Gives the source path to copy files from
  """
  def source_path(path) do
    Application.app_dir(:veil, Path.join(["priv", "templates", path]))
  end

  @doc """

  """
  def append_config_file(%{config_path: config_path} = config) do
    config_source = source_path(Path.join(["config", "config.exs"]))

    if File.exists?(config_path) and File.exists?(config_source) do
      previous = File.read!(config_path)
      config_data = EEx.eval_file(config_source, config |> Map.to_list())

      confirmed =
        if String.contains?(previous, "-- Veil Configuration") do
          Mix.shell().yes?(
            "Your config file already contains Veil configuration. Are you sure you want to add another?"
          )
        else
          true
        end

      if confirmed do
        File.write!(config_path, previous <> "\n\n" <> config_data)

        Mix.shell().info([
          :yellow,
          "* amended ",
          :reset,
          "config/config.exs - Veil config added"
        ])
      else
        Mix.shell().info([
          :yellow,
          "* skipping ",
          :reset,
          "config/config.exs - Veil config skipped"
        ])
      end

      config
    else
      Mix.raise("Cannot find config file at: #{config_path} or #{config_source}")
    end
  end

  @doc """
  Copies the files in the main directory over, and evaluates against EEx using the config
  """
  def copy_main_dir(%{main_path: main_path} = config) do
    files = ["clean.ex", "request.ex", "session.ex", "user.ex", "veil.ex"]
    source_dir = source_path(Path.join(["lib", "main", "veil"]))
    target_dir = Path.join([main_path, "veil"])
    copy_files(files, source_dir, target_dir, config)
    config
  end

  @doc """
  Copies the files in the web directory over, and evaluates against EEx using the config
  """
  def copy_web_dir(config) do
    config
    |> copy_web_files_map(%{
      "controllers" => ["fallback_controller.ex", "session_controller.ex", "user_controller.ex"],
      "emails" => ["login_email.ex", "mailer.ex"],
      "plugs" => ["authenticate.ex", "user_id.ex", "user.ex"],
      "views" => ["email_view.ex", "error_view.ex", "session_view.ex", "user_view.ex"]
    })
  end

  @doc """
  Copies the templates in the web directory over (only if html)
  """
  def copy_templates(%{html?: true} = config) do
    config
    |> copy_web_files_map(%{
      "templates" => [
        "email/login.html.eex",
        "user/form.html.eex",
        "user/new.html.eex",
        "user/show.html.eex"
      ]
    })
  end

  def copy_templates(%{html?: false} = config) do
    config
    |> copy_web_files_map(%{
      "templates" => [
        "email/login.html.eex"
      ]
    })
  end

  defp copy_web_files_map(%{web_path: web_path} = config, map) do
    Enum.each(map, fn {folder, files} ->
      source_dir = source_path(Path.join(["lib", "web", folder, "veil"]))
      target_dir = Path.join([web_path, folder, "veil"])
      copy_files(files, source_dir, target_dir, config)
    end)

    config
  end

  @doc """
  Create directory and copy list of files across
  """
  def copy_files(files, source_dir, target_dir, config) do
    binding = Map.to_list(config)
    Enum.each(files, &copy_file_evaluate(&1, source_dir, target_dir, binding))
  end

  @doc """
  Uses Mix.Generator to copy the file across, evaluating against the binding
  """
  def copy_file_evaluate(filename, source_dir, target_dir, binding) do
    target = Path.join([target_dir, filename])
    contents = EEx.eval_file(Path.join(source_dir, filename), binding)
    Mix.Generator.create_file(target, contents)
  end

  @doc """
  Copy the migration to the priv/repo/migrations folder
  """
  def copy_migration(%{migration_path: migration_path} = config) do
    migration_source = source_path(Path.join(["priv", "repo", "migrations", "add_veil.exs"]))
    migration_data = EEx.eval_file(migration_source, config |> Map.to_list())
    Mix.Generator.create_file(migration_path, migration_data)

    config
  end

  @doc """
  Amend the default layout file to add a Sign-in link in the top right.
  Do nothing if the app is an api.
  """
  def amend_default_template(%{html?: false} = config) do
    config
  end

  def amend_default_template(%{layout_path: layout_path, web_path: web_path} = config) do
    layout_source = source_path(Path.join(["lib", "web", "templates", "layout", "app.html.eex"]))

    config =
      if File.exists?(layout_path) and File.exists?(layout_source) do
        previous = File.read!(layout_path)
        layout_data = File.read!(layout_source)

        to_replace = "<a href=\"https://hexdocs.pm/phoenix/overview.html\">Get Started</a>"

        if String.contains?(previous, to_replace) do
          File.write!(layout_path, String.replace(previous, to_replace, layout_data))

          Mix.shell().info([
            :yellow,
            "* amended ",
            :reset,
            "#{web_path}/templates/layout/app.html.eex - added sign-in link"
          ])

          Map.put(config, :non_default_layout, false)
        else
          Mix.shell().info([
            :yellow,
            "* skipping ",
            :reset,
            "#{web_path}/templates/layout/app.html.eex - already customised"
          ])

          Map.put(config, :non_default_layout, true)
        end
      else
        if config[:html?] do
          Mix.shell().info([
            :yellow,
            "* skipping ",
            :reset,
            "#{web_path}/templates/layout/app.html.eex - no longer exists"
          ])

          Map.put(config, :non_default_layout, true)
        end
      end

    config
  end

  def amend_router(
        %{router_path: router_path, web_path: web_path, web_module: web_module} = config
      ) do
    if File.exists?(router_path) do
      previous = File.read!(router_path)

      amended =
        previous
        |> update_string(
          config[:html?],
          "plug :put_secure_browser_headers",
          """
          plug :put_secure_browser_headers
          plug #{web_module}.Plugs.Veil.UserId
          plug #{web_module}.Plugs.Veil.User
          """,
          [
            :yellow,
            "* amended ",
            :reset,
            "#{router_path} - UserId & User plugs added to html pipeline"
          ]
        )
        |> update_string(
          config[:html?],
          "plug(:put_secure_browser_headers)",
          """
          plug(:put_secure_browser_headers)
          plug(#{web_module}.Plugs.Veil.UserId)
          plug(#{web_module}.Plugs.Veil.User)
          """,
          [
            :yellow,
            "* amended ",
            :reset,
            "#{router_path} - UserId & User plugs added to html pipeline"
          ]
        )
        |> update_string(
          !config[:html?],
          "plug :accepts, [\"json\"]",
          """
          plug :accepts, ["json"]
          plug #{web_module}.Plugs.Veil.UserId
          plug #{web_module}.Plugs.Veil.User
          """,
          [
            :yellow,
            "* amended ",
            :reset,
            "#{router_path} - UserId & User plugs added to api pipeline"
          ]
        )
        |> update_string(
          !config[:html?],
          "plug(:accepts, [\"json\"])",
          """
          plug(:accepts, ["json"])
          plug(#{web_module}.Plugs.Veil.UserId)
          plug(#{web_module}.Plugs.Veil.User)
          """,
          [
            :yellow,
            "* amended ",
            :reset,
            "#{router_path} - UserId & User plugs added to api pipeline"
          ]
        )
        |> insert_routes(config)

      File.write!(router_path, amended)
      Mix.Tasks.Format.run([Path.join(web_path, "router.ex")])
      config
    else
      Mix.shell().info([:red, "error ", :reset, "#{router_path} - cannot be found"])
      show_router_instructions(config)
      config
    end
  end

  defp update_string(string, true, find, replace, message) do
    if String.contains?(string, find) do
      Mix.shell().info(message)
      String.replace(string, find, replace)
    else
      string
    end
  end

  defp update_string(string, false, _, _, _) do
    string
  end

  defp insert_routes(string, %{router_path: router_path} = config) do
    insert_source = source_path(Path.join(["lib", "web", "router", "insert.ex"]))
    insert = EEx.eval_file(insert_source, config |> Map.to_list())

    if String.slice(string, -3, 3) == "end" do
      Mix.shell().info([:yellow, "* amended ", :reset, "#{router_path} - Veil routes added"])
      String.slice(string, 0, String.length(string) - 3) <> insert
    else
      if String.slice(string, -4, 4) == "end\n" do
        Mix.shell().info([:yellow, "* amended ", :reset, "#{router_path} - Veil routes added"])
        String.slice(string, 0, String.length(string) - 4) <> insert
      else
        if String.slice(string, -5, 5) == "end\n\n" do
          Mix.shell().info([:yellow, "* amended ", :reset, "#{router_path} - Veil routes added"])
          String.slice(string, 0, String.length(string) - 5) <> insert
        else
          Mix.shell().info([:red, "error ", :reset, "failed to insert Veil routes into Router."])
          show_router_instructions(config)
          string
        end
      end
    end
  end

  defp show_final_instructions(config) do
    config
    |> show_link_instructions()
    |> show_config_instructions()
    |> show_start_instructions()
  end

  defp show_config_instructions(%{web_module: web_module} = config) do
    Mix.shell().info(["\n", :cyan, "Final steps:", :reset])

    Mix.shell().info("""

    Update the Veil configuration in your `config.exs` file to add an API key for your
    preferred email service (for more details on the email options, please refer to the
    [Swoosh Documentation](https://github.com/swoosh/swoosh)).

      config :veil, #{web_module}.Veil.Mailer,
        adapter: Swoosh.Adapters.Sendgrid,
        api_key: "your-api-key"
    """)

    config
  end

  defp show_start_instructions(config) do
    Mix.shell().info("""
    Launch your server and open http://localhost:4000/ in your browser.

      mix phx.server
      mix ecto.migrate

    If you click the sign-in link in the top right and enter your email address, you'll be
    sent an email with a sign-in button. Click this to re-open the website and you'll see
    you are now authenticated.
    """)

    config
  end

  defp show_router_instructions(%{
         main_module: main_module,
         web_module: web_module,
         web_path: web_path
       }) do
    Mix.shell().info("""
    You will need to add the following to your #{web_path}/router.ex file manually.

    defmodule #{web_module}.Router do
      use #{web_module}, :router

      # ...

      ### Add this block
      # Default Routes for Veil
      scope "/veil", #{web_module}.Veil do
        pipe_through(:browser)

        get("/users/new", UserController, :new)
        post("/users", UserController, :create)
        get("/sessions/new/:request_unique_id", SessionController, :create)
        get("/sessions/signout/:session_unique_id", SessionController, :delete)
      end

      ### Add this block
      # Add your routes that require authentication in this block.
      # Alternatively, you can use the default block and authenticate in the controllers.
      # See the Veil README for more.
      scope "/", #{web_module} do
        pipe_through([:browser, defmodule #{main_module}.Veil do
      end
    """)
  end

  defp show_link_instructions(%{non_default_layout: true} = config) do
    Mix.shell().info("""

    If your default layout page (`templates/layout/app.html.eex`) was already
    modified or replaced, e.g. you see
    `* skipping lib/sunrise_web/templates/layout/app.html.eex`
    above then you'll need to manually add link markup similar to this:

      <%= if veil_user_id = assigns[:veil_user_id] do %>
        Authenticated as <%= veil_user_id %>
        <a href="<%= session_path(@conn, :delete, @session_unique_id) %>">Sign out</a>
      <% else %>
        <a href="<%= user_path(@conn, :new) %>">Sign in</a>
      <% end %>
    """)

    config
  end

  defp show_link_instructions(config), do: config
end

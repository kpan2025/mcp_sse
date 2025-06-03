defmodule MCP.MessageRouter do
  @moduledoc false

  # Internal routing implementation
  # Routes MCP JSON-RPC messages to appropriate server implementations.
  # Provides default handling for basic messages like ping.

  require Logger

  @doc false
  def handle_message(session_id, %{"method" => "notifications/initialized"} = message) do
    Logger.info("sid: #{session_id} Received initialized notification")
    Logger.debug("Full message: #{inspect(message, pretty: true)}")
    # Notifications don't expect responses
    {:ok, nil}
  end

  @doc false
  def handle_message(session_id, %{"method" => method, "id" => id} = message) do
    server_implementation = Application.get_env(:mcp_sse, :mcp_server, MCP.DefaultServer)
    Logger.info("sid: #{session_id} Routing MCP message - Method: #{method}, ID: #{id}")
    Logger.debug("Full message: #{inspect(message, pretty: true)}")

    case method do
      "ping" ->
        Logger.debug("Handling ping request")
        server_implementation.handle_ping(session_id, id)

      "initialize" ->
        Logger.info(
          "Handling initialize request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_initialize(session_id, id, message["params"])

      "completion/complete" ->
        Logger.debug(
          "Handling complete request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_complete(session_id, id, message["params"])

      "prompts/list" ->
        Logger.debug("Handling prompts list request")
        server_implementation.handle_list_prompts(session_id, id, message["params"])

      "prompts/get" ->
        Logger.debug(
          "Handling prompt get request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_get_prompt(session_id, id, message["params"])

      "resources/list" ->
        Logger.debug("Handling resources list request")
        server_implementation.handle_list_resources(session_id, id, message["params"])

      "resources/read" ->
        Logger.debug(
          "Handling resource read request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_read_resource(session_id, id, message["params"])

      "tools/list" ->
        Logger.debug("Handling tools list request")
        server_implementation.handle_list_tools(session_id, id, message["params"])

      "tools/call" ->
        Logger.debug(
          "Handling tool call request with params: #{inspect(message["params"], pretty: true)}"
        )

        server_implementation.handle_call_tool(session_id, id, message["params"])

      other ->
        Logger.warning("Received unsupported method: #{other}")

        {:error,
         %{
           jsonrpc: "2.0",
           id: id,
           error: %{
             code: -32601,
             message: "Method not found",
             data: %{
               name: other
             }
           }
         }}
    end
  end

  @doc false
  def handle_message(session_id, unknown_message) do
    Logger.error(
      "sid: #{session_id} Received invalid message format: #{inspect(unknown_message, pretty: true)}"
    )

    {:error,
     %{
       jsonrpc: "2.0",
       id: nil,
       error: %{
         code: -32600,
         message: "Invalid Request",
         data: %{
           received: unknown_message
         }
       }
     }}
  end
end

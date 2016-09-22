defmodule MiniIrcd.Client do
  use GenServer
  require Logger

  def start(client) do
    GenServer.start(__MODULE__, [client], [])
  end

  def init([client]) do
    {:ok, %{client: client}, 0}
  end

  def handle_info(:timeout, %{client: client} = state) do
    #Logger.debug "#{inspect __MODULE__} waiting for a line"
    #Maybe even better to create two Processes to handle read and write separately
    #then we can wait for packet infinity and don't use the resource with the loop
    case Socket.Stream.recv(client, [timeout: 10000]) do
      {:error, :ebadf} ->
        GenServer.stop(self, :normal)
        {:noreply, state}
      {:error, :timeout} ->
        {:noreply, state, 0}
      {:ok, line} ->
      IO.inspect line
      case parse_request(line) do
        :exit ->
          GenServer.stop(self, :normal)
          IO.inspect(:exit)
        res when is_list(res) ->
          res |> Enum.each(fn (r) -> Socket.Stream.send(client, r <> "\r\n") end)
          IO.inspect res
        oth ->
          IO.inspect(oth)
      end
      {:noreply, state, 0}
    end
  end

  def parse_request(nil), do: nil
  def parse_request("CAP LS\r\n"), do: nil
  def parse_request(["NICK" | tail]) do
    tail
  end
  def parse_request(["USER" | _tail]) do
    [
      ":miniircd.local 001 milad :Hi, welcome to IRC",
    ]
  end

  def parse_request(["MODE" | _tail]) do
    [":miniircd.local 002 milad :Unknown MODE flag"]
  end

  def parse_request(["PING" | _tail]) do
    [":miniircd.local PONG"]
  end

  def parse_request(["QUIT" | _tail]) do
    :exit
  end
  def parse_request([_head| _tail] = cmd) do
    IO.inspect cmd
    throw :not_imp
  end

  def parse_request(request) do
    request
    |> String.trim
    |> String.split(" ", parts: 2)
    |> parse_request
  end
end

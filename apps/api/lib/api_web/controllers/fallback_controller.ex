defmodule ApiAppWeb.FallbackController do
  use ApiWeb, :controller

  def not_found(conn, _params) do
    send_resp(conn, 404, "Not found")
  end
end

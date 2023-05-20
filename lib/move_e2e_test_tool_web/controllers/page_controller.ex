defmodule MoveE2eTestToolWeb.PageController do
  use MoveE2eTestToolWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end
end

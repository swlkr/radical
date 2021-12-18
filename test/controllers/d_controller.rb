# frozen_string_literal: true

class DController < Radical::Controller
  def index
    plain "c:#{params['c_id']}"
  end

  def show
    plain "d:#{params['id']}"
  end
end

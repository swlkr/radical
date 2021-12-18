# frozen_string_literal: true

class TodoController < Radical::Controller
  # GET /todo
  def index
    plain 'todo#index'
  end

  # GET /todo/:id/edit
  def edit
    plain "todo#edit { id: #{params['id']} }"
  end
end

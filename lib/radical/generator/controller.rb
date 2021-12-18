# frozen_string_literal: true

<<~RB
  # frozen_string_literal: true

  class #{camel_case}Controller < Controller
    def index
      @#{snake_case}s = #{camel_case}.all
    end

    def show; end

    def new
      @#{snake_case} = #{camel_case}.new
    end

    def create
      @#{snake_case} = #{camel_case}.new(#{snake_case}_params)

      if @#{snake_case}.save
        redirect #{snake_case}_path, notice: '#{camel_case} created'
      else
        view :new
      end
    end

    def edit; end

    def update
      if #{snake_case}.update(#{snake_case}_params)
        redirect #{snake_case}_path, notice: '#{camel_case} updated'
      else
        view :edit
      end
    end

    def destroy
      #{snake_case}.delete

      redirect #{snake_case}_path, notice: '#{camel_case} deleted'
    end

    private

    def #{snake_case}_params
      params.slice(#{params})
    end

    def #{snake_case}
      @#{snake_case} = #{camel_case}.find params['id']
    end
  end
RB

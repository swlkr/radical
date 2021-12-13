# frozen_string_literal: true

<<~RB
  # frozen_string_literal: true

  class #{plural_constant} < Controller
    def index
      @#{plural} = #{singular_constant}.all
    end

    def show; end

    def new
      @#{singular} = #{singular_constant}.new
    end

    def create
      @#{singular} = #{singular_constant}.new(#{singular}_params)

      if @#{singular}.save
        flash[:success] = '#{singular_constant} created'
        redirect #{plural}_path
      else
        render :new
      end
    end

    def edit; end

    def update
      if #{singular}.update(#{singular}_params)
        flash[:success] = '#{singular_constant} updated'
        redirect #{plural}_path
      else
        render :edit
      end
    end

    def destroy
      if #{singular}.destroy
        flash[:success] = '#{singular_constant} destroyed'
      else
        flash[:error] = 'Error destroying #{singular_constant}'
      end

      redirect #{plural}_path
    end

    private

    def #{singular}_params
      params['#{singular}'].slice(#{params})
    end

    def #{singular}
      @#{singular} = #{singular_constant}.find(params['id'])
    end
  end
RB

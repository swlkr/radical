module Radical
  class View
    class << self
      attr_accessor :_views_path

      def view_path(dir, name)
        File.join(@_views_path, 'views', dir, "#{name}.erb")
      end

      def file(dir, name)
        File.read(view_path(dir, name))
      rescue Errno::ENOENT
        raise "Could not find view file: #{view_path(dir, name)}. You need to create it"
      end

      def compiled(dir, name)
        ERB.new(file(dir, name))
      end

      def path(path = nil, test = Env.test?)
        @_views_path = path || ((test ? 'test' : '') + __dir__)
      end

      def render(dir, name, binding)
        View.compiled(dir, name)&.result(binding)
      end
    end
  end
end

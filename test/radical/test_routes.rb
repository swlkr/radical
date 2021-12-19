# frozen_string_literal: true

require 'minitest/autorun'
require 'radical'
require 'models/test_model'

class M < TestModel; end

class MsController < Radical::Controller
  def index; end

  def new; end

  def show; end

  def edit; end
end

class NsController < Radical::Controller
  def new; end

  def show; end

  def edit; end
end

class HController < Radical::Controller
  def index; end
end

class FsController < Radical::Controller
  def index; end
end

class GsController < Radical::Controller
  def index; end

  def show; end

  def edit; end

  def new; end
end

class HsController < Radical::Controller
  def index; end
end

class F < TestModel; end

class G < TestModel; end

class TestRoutes < Minitest::Test
  def test_resource_paths
    Radical::Routes.resource :NsController

    assert NsController.method_defined?(:new_ns_path)
    assert NsController.method_defined?(:ns_path)
    assert NsController.method_defined?(:edit_ns_path)

    n = NsController.new Rack::Request.new({})

    assert_equal '/ns', n.send(:ns_path)
    assert_equal '/ns/edit', n.send(:edit_ns_path)
    assert_equal '/ns/new', n.send(:new_ns_path)
  end

  def test_resources_paths
    Radical::Routes.resources :MsController

    assert MsController.method_defined?(:new_ms_path)
    assert MsController.method_defined?(:ms_path)
    assert MsController.method_defined?(:edit_ms_path)

    m = MsController.new Rack::Request.new({})
    @m = M.new(id: 123)

    assert_equal '/ms', m.send(:ms_path)
    assert_equal '/ms/123', m.send(:ms_path, @m)
    assert_equal '/ms/123/edit', m.send(:edit_ms_path, @m)
    assert_equal '/ms/new', m.send(:new_ms_path)
  end

  def test_root_path
    Radical::Routes.root :HController

    assert HController.method_defined?(:h_path)

    h = HController.new Rack::Request.new({})

    assert_equal '/', h.send(:h_path)
  end

  def test_nested_paths
    Radical::Routes.resources :FsController do
      Radical::Routes.resources :GsController
    end

    assert FsController.method_defined?(:fs_path)
    assert !FsController.method_defined?(:new_fs_path)
    assert GsController.method_defined?(:fs_gs_path)
    assert GsController.method_defined?(:new_fs_gs_path)

    req = Rack::Request.new({})

    fs = FsController.new req
    gs = GsController.new req
    f = F.new(id: 123)
    g = G.new(id: 321)

    assert_equal '/fs', fs.fs_path
    assert_equal '/fs/123/gs/new', gs.new_fs_gs_path(f)
    assert_equal '/gs/321/edit', gs.edit_gs_path(g)
    assert_equal '/fs/123/gs', gs.fs_gs_path(f)
    assert_equal '/gs/321', gs.gs_path(g)
  end
end

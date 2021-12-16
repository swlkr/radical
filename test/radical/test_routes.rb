# frozen_string_literal: true

require 'minitest/autorun'
require 'radical'
require 'models/test_model'

class M < TestModel; end

class Ms < Radical::Controller
  def index; end

  def new; end

  def show; end

  def edit; end
end

class Ns < Radical::Controller
  def new; end

  def show; end

  def edit; end
end

class H < Radical::Controller
  def index; end
end

class Fs < Radical::Controller
  def index; end
end

class Gs < Radical::Controller
  def index; end

  def show; end

  def edit; end

  def new; end
end

class Hs < Radical::Controller
  def index; end
end

class F < TestModel; end

class G < TestModel; end

class TestRoutes < Minitest::Test
  def test_resource_paths
    Radical::Routes.resource :Ns

    assert Ns.method_defined?(:new_ns_path)
    assert Ns.method_defined?(:ns_path)
    assert Ns.method_defined?(:edit_ns_path)

    n = Ns.new Rack::Request.new({})

    assert_equal '/ns', n.send(:ns_path)
    assert_equal '/ns/edit', n.send(:edit_ns_path)
    assert_equal '/ns/new', n.send(:new_ns_path)
  end

  def test_resources_paths
    Radical::Routes.resources :Ms

    assert Ms.method_defined?(:new_ms_path)
    assert Ms.method_defined?(:ms_path)
    assert Ms.method_defined?(:edit_ms_path)

    m = Ms.new Rack::Request.new({})
    @m = M.new(id: 123)

    assert_equal '/ms', m.send(:ms_path)
    assert_equal '/ms/123', m.send(:ms_path, @m)
    assert_equal '/ms/123/edit', m.send(:edit_ms_path, @m)
    assert_equal '/ms/new', m.send(:new_ms_path)
  end

  def test_root_path
    Radical::Routes.root :H

    assert H.method_defined?(:h_path)

    h = H.new Rack::Request.new({})

    assert_equal '/', h.send(:h_path)
  end

  def test_nested_paths
    Radical::Routes.resources :Fs do
      Radical::Routes.resources :Gs
    end

    assert Fs.method_defined?(:fs_path)
    assert !Fs.method_defined?(:new_fs_path)
    assert Gs.method_defined?(:fs_gs_path)
    assert Gs.method_defined?(:new_fs_gs_path)

    req = Rack::Request.new({})

    fs = Fs.new req
    gs = Gs.new req
    f = F.new(id: 123)
    g = G.new(id: 321)

    assert_equal '/fs', fs.fs_path
    assert_equal '/fs/123/gs/new', gs.new_fs_gs_path(f)
    assert_equal '/gs/321/edit', gs.edit_gs_path(g)
    assert_equal '/fs/123/gs', gs.fs_gs_path(f)
    assert_equal '/gs/321', gs.gs_path(g)
  end
end

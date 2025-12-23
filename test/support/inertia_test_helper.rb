# frozen_string_literal: true

module InertiaTestHelper
  class InertiaRenderWrapper
    attr_reader :view_data, :props, :component

    def initialize
      @view_data = nil
      @props = nil
      @component = nil
    end

    def call(params)
      assign_locals(params)
      @render_method&.call(params)
    end

    def wrap_render(render_method)
      @render_method = render_method
      self
    end

    private

    def assign_locals(params)
      if params[:locals].present?
        @view_data = params[:locals].except(:page)
        @props = params[:locals][:page][:props].deep_stringify_keys
        @component = params[:locals][:page][:component]
      else
        @view_data = {}
        json = JSON.parse(params[:json])
        @props = json["props"]
        @component = json["component"]
      end
    end
  end

  def inertia
    InertiaTestHelper.current_wrapper
  end

  class << self
    attr_accessor :current_wrapper
  end

  def setup_inertia_rendering
    InertiaTestHelper.current_wrapper = nil
    return if @_inertia_setup_done

    original_new = InertiaRails::Renderer.method(:new)

    InertiaRails::Renderer.define_singleton_method(:new) do |component, controller, request, response, render, **named_args|
      wrapper = InertiaTestHelper::InertiaRenderWrapper.new.wrap_render(render)
      InertiaTestHelper.current_wrapper = wrapper
      original_new.call(component, controller, request, response, wrapper, **named_args)
    end

    @_inertia_setup_done = true
  end

  def assert_inertia_component(expected)
    assert_not_nil inertia, "No Inertia render was captured"
    assert_equal expected, inertia.component
  end

  def assert_inertia_props(expected)
    assert_not_nil inertia, "No Inertia render was captured"
    expected.each do |key, value|
      assert_equal value, inertia.props[key.to_s], "Expected prop #{key} to be #{value}"
    end
  end

  def assert_inertia_props_include(*keys)
    assert_not_nil inertia, "No Inertia render was captured"
    keys.each do |key|
      assert inertia.props.key?(key.to_s), "Expected props to include #{key}"
    end
  end
end

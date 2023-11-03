# frozen_string_literal: true

module ViewComponentContrib
  module Preview
    # First, enable abstract classes (if not already extended)
    unless ViewComponent::Preview.singleton_class.is_a?(ViewComponentContrib::Preview::Abstract)
      ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract
    end

    # Base view component class with extensions already included
    class Base < ViewComponent::Preview
      self.abstract_class = true

      include DefaultTemplate

      DEFAULT_CONTAINER_CLASS = ""

      class << self
        # Support layout inheritance
        def inherited(child)
          child.layout(@layout) if defined?(@layout)
          super
        end

        attr_writer :container_class

        def container_class
          return @container_class if defined?(@container_class)

          @container_class =
            if superclass.respond_to?(:container_class)
              superclass.container_class
            else
              DEFAULT_CONTAINER_CLASS
            end
        end

        def render_args(...)
          super.tap do |res|
            res[:locals] ||= {}
            build_component_instance(res[:locals])
            res[:locals][:container_class] ||= container_class
          end
        end

        private

        def build_component_instance(locals)
          return locals unless locals[:component].nil?
          locals[:component] = name.sub(/Preview$/, "Component").safe_constantize&.new
        rescue => e
          locals[:component] = nil
          locals[:error] = e.message
        end
      end

      # Shortcut for render_with_template(locals: ...)
      def render_with(**locals)
        render_with_template(locals: locals)
      end

      # Shortcut for render_with_template(locals: {component: ...})
      def render_component(component_or_props = nil, &block)
        component = if component_or_props.is_a?(::ViewComponent::Base)
          component_or_props
        else
          self.class.name.sub(/Preview$/, "Component").constantize.new(**(component_or_props || {}))
        end

        render_with(component: component, content_block: block)
      end
    end
  end
end

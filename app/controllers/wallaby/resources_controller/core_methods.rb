module Wallaby::ResourcesController::CoreMethods
  extend ActiveSupport::Concern

  class_methods do
    def resources_name condition = self < Wallaby::ResourcesController
      if condition
        Wallaby::Utils.to_resources_name name.gsub('Controller', '')
      end
    end

    def model_class target_resources_name = resources_name, condition = self < Wallaby::ResourcesController
      if condition
        Wallaby::Utils.to_model_name(target_resources_name).constantize
      end
    end
  end

  def resources_name
    self.class.resources_name || params[:resources]
  end

  def resource_name
    resources_name.singularize
  end

  def model_class
    self.class.model_class || self.class.model_class(resource_name, true)
  end

  def model_decorator
    @model_decorator ||= begin
      target_decorator_class = Wallaby::Decorator.subclasses.find do |klass|
        klass.model_class == model_class
      end
      target_decorator_class || Wallaby::ModelDecorator.new(model_class)
    end
  end
end
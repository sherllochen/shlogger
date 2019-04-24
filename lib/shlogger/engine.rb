module Shlogger
  class Engine < ::Rails::Engine
    isolate_namespace Shlogger

    config.to_prepare do
      # 载入engine对application的decorator
      Dir.glob(Engine.root.join("app", "decorators", "**", "*_decorator*.rb")).each do |c|
        require_dependency(c)
      end

      # 载入application对engine的decorator
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end

  end
end

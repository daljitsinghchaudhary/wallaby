module Wallaby
  class ResourcesController < CoreController
    include CoreMethods, CreateAction, UpdateAction, DestroyAction, HelperMethods

    before_action :build_up_view_paths

    def index
      collection
    end

    def new
      resource
    end

    def create
      if created?
        create_success
      else
        create_error
      end
    end

    def show
      resource
    end

    def edit
      resource
    end

    def update
      if updated?
        update_success
      else
        update_error
      end
    end

    def destroy
      if destroyed?
        destroy_success
      else
        destroy_error
      end
    end

    def search
      # TODO: for ransack
    end

    def history
      # TODO: for papertrail
    end

    protected
    def build_up_view_paths
      lookup_context.prefixes = PrefixesBuilder.new(self).build
    end
  end
end
require 'rails_helper'

describe Wallaby::ResourcesController do
  describe '#healthy' do
    it 'returns healthy' do
      get :healthy
      expect(response.body).to eq 'healthy'

      get :healthy, format: :json
      expect(response.body).to eq 'healthy'
    end
  end

  describe '#home' do
    it 'renders home' do
      routes.draw { get 'home' => 'wallaby/resources#home' }
      get :home
      expect(response).to be_successful
      expect(response).to render_template :home
    end
  end

  describe 'CRUD' do
    before do
      routes.draw do
        get ':resources', to: 'wallaby/resources#index', as: :resources
        get ':resources/:id', to: 'wallaby/resources#show', as: :resource
        get ':resources/new', to: 'wallaby/resources#new'
        get ':resources/:id/edit', to: 'wallaby/resources#edit'
        post ':resources', to: 'wallaby/resources#create'
        patch ':resources/:id', to: 'wallaby/resources#update'
        delete ':resources/:id', to: 'wallaby/resources#destroy'
      end
    end

    after { Rails.application.reload_routes! }

    describe '#index' do
      it 'renders index' do
        all_postgres_type = AllPostgresType.create string: 'something'
        get :index, params: { resources: 'all_postgres_type' }
        expect(assigns(:collection)).to include all_postgres_type
        expect(response).to be_successful
        expect(response).to render_template :index
      end
    end

    describe '#show' do
      it 'renders show' do
        all_postgres_type = AllPostgresType.create string: 'something'
        get :show, params: { resources: 'all_postgres_type', id: all_postgres_type.id }
        expect(assigns(:resource).string).to eq all_postgres_type.string
        expect(response).to be_successful
        expect(response).to render_template :show
      end
    end

    describe '#new' do
      it 'renders new' do
        get :new, params: { resources: 'all_postgres_type' }
        expect(assigns(:resource)).to be_a AllPostgresType
        expect(response).to be_successful
        expect(response).to render_template :new
      end
    end

    describe '#create' do
      it 'renders create' do
        post :create, params: { resources: 'all_postgres_type', all_postgres_type: { string: 'something' } }
        all_postgres_type = AllPostgresType.first
        expect(assigns(:resource).string).to eq all_postgres_type.string
        expect(response).to redirect_to "/admin/all_postgres_types/#{all_postgres_type.id}"
      end
    end

    describe '#edit' do
      it 'renders edit' do
        all_postgres_type = AllPostgresType.create string: 'something'
        get :edit, params: { resources: 'all_postgres_type', id: all_postgres_type.id }
        expect(assigns(:resource).string).to eq all_postgres_type.string
        expect(response).to be_successful
        expect(response).to render_template :edit
      end
    end

    describe '#update' do
      it 'renders update' do
        all_postgres_type = AllPostgresType.create string: 'something'
        put :update, params: { resources: 'all_postgres_type', id: all_postgres_type.id, all_postgres_type: { string: 'something' } }
        expect(assigns(:resource).string).to eq all_postgres_type.string
        expect(response).to redirect_to "/admin/all_postgres_types/#{all_postgres_type.id}"
      end
    end

    describe '#destroy' do
      it 'renders destroy' do
        all_postgres_type = AllPostgresType.create string: 'something'
        delete :destroy, params: { resources: 'all_postgres_type', id: all_postgres_type.id }
        expect(assigns(:resource).string).to eq all_postgres_type.string
        expect(response).to redirect_to '/admin/all_postgres_types'
      end
    end
  end

  describe 'class methods ' do
    describe '.resources_name' do
      it 'returns nil' do
        expect(described_class.resources_name).to be_nil
      end
    end

    describe '.model_class' do
      it 'returns nil' do
        expect(described_class.model_class).to be_nil
      end
    end
  end

  describe 'instance methods ' do
    let!(:model_class) { Product }

    before do
      controller.params[:resources] = 'products'
    end

    describe '#current_model_decorator' do
      it 'returns model decorator for default model_class' do
        model_decorator = controller.send :current_model_decorator
        expect(model_decorator).to be_a Wallaby::ModelDecorator
        expect(model_decorator.model_class).to eq model_class
        expect(assigns(:current_model_decorator)).to eq model_decorator
      end
    end

    describe '#current_model_service' do
      it 'returns model servicer for default model_class' do
        model_servicer = controller.send :current_model_service
        expect(model_servicer).to be_a Wallaby::ModelServicer
        expect(assigns(:current_model_service)).to eq model_servicer
      end
    end

    describe '#paginate' do
      let(:query) { Product.where(nil) }
      before do
        controller.request.format = :json
      end

      it 'returns the query' do
        paginate = controller.send :paginate, query
        expect(paginate.to_sql).to eq 'SELECT "products".* FROM "products"'
      end

      context 'when page param is provided' do
        it 'paginate the query' do
          controller.params[:page] = 8
          paginate = controller.send :paginate, query
          expect(paginate.to_sql).to eq 'SELECT  "products".* FROM "products" LIMIT 20 OFFSET 140'
        end
      end

      context 'when per param is provided' do
        it 'paginate the query' do
          controller.params[:per] = 8
          paginate = controller.send :paginate, query
          expect(paginate.to_sql).to eq 'SELECT  "products".* FROM "products" LIMIT 8 OFFSET 0'
        end
      end

      context 'when page param is provided' do
        it 'paginate the query' do
          controller.request.format = :html
          paginate = controller.send :paginate, query
          expect(paginate.to_sql).to eq 'SELECT  "products".* FROM "products" LIMIT 20 OFFSET 0'
        end
      end
    end

    describe '#collection' do
      it 'expects call from current_model_decorator' do
        controller.params[:per] = 10
        controller.params[:page] = 2

        collection = controller.send :collection
        expect(assigns(:collection)).to eq collection
        expect(collection.to_sql).to eq 'SELECT  "products".* FROM "products" LIMIT 10 OFFSET 10'
      end
    end

    describe '#resource' do
      it 'returns new resource' do
        expect(controller.send(:resource)).to be_new_record
      end

      context 'when resource id is provided' do
        it 'returns the resource' do
          resource = Product.create!(name: 'new Product')
          controller.params[:id] = resource.id
          expect(controller.send(:resource)).to eq resource
        end
      end
    end

    describe '#resource_id' do
      it 'equals params[:id]' do
        controller.params[:id] = 'abc123'
        expect(controller.send(:resource_id)).to eq 'abc123'
      end
    end

    describe '#lookup_context' do
      it 'returns a caching lookup_context' do
        controller.params[:resources] = 'wallaby/resources'
        expect(controller.send(:lookup_context)).to be_a Wallaby::LookupContextWrapper
        expect(controller.instance_variable_get(:@_lookup_context)).to be_a Wallaby::LookupContextWrapper
      end
    end

    describe '#_prefixes' do
      module Space
        class PlanetsController < Wallaby::ResourcesController; end
        class Planet; end
      end

      before do
        controller.request.env['SCRIPT_NAME'] = '/admin'
        controller.params[:action] = 'index'
      end

      it 'returns prefixes' do
        controller.params[:resources] = 'wallaby/resources'
        expect(controller.send(:_prefixes)).to eq ['wallaby/resources/index', 'wallaby/resources']
      end

      context 'when current_resources_name is different' do
        it 'returns prefixes' do
          controller.params[:resources] = 'products'
          expect(controller.send(:_prefixes)).to eq ['admin/products/index', 'admin/products', 'wallaby/resources/index', 'wallaby/resources']
        end
      end

      context 'for descendants' do
        describe Space::PlanetsController do
          it 'returns prefixes' do
            controller.params[:resources] = 'space/planets'
            expect(controller.send(:_prefixes)).to eq ['space/planets/index', 'space/planets', 'wallaby/resources/index', 'wallaby/resources']
          end

          context 'when current_resources_name is different' do
            it 'returns prefixes' do
              controller.params[:resources] = 'mars'
              expect(controller.send(:_prefixes)).to eq ['admin/mars/index', 'admin/mars', 'space/planets/index', 'space/planets', 'wallaby/resources/index', 'wallaby/resources']
            end
          end
        end
      end

      %w(new create edit update).each do |action_name|
        context 'action is new' do
          before { controller.params[:action] = action_name }

          it 'returns prefixes' do
            controller.params[:resources] = 'wallaby/resources'
            expect(controller.send(:_prefixes)).to eq ['wallaby/resources/form', 'wallaby/resources']
          end

          context 'when current_resources_name is different' do
            it 'returns prefixes' do
              controller.params[:resources] = 'products'
              expect(controller.send(:_prefixes)).to eq ['admin/products/form', 'admin/products', 'wallaby/resources/form', 'wallaby/resources']
            end
          end

          context 'for descendants' do
            describe Space::PlanetsController do
              it 'returns prefixes' do
                controller.params[:resources] = 'space/planets'
                expect(controller.send(:_prefixes)).to eq ['space/planets/form', 'space/planets', 'wallaby/resources/form', 'wallaby/resources']
              end

              context 'when current_resources_name is different' do
                it 'returns prefixes' do
                  controller.params[:resources] = 'mars'
                  expect(controller.send(:_prefixes)).to eq ['admin/mars/form', 'admin/mars', 'space/planets/form', 'space/planets', 'wallaby/resources/form', 'wallaby/resources']
                end
              end
            end
          end
        end
      end
    end
  end

  describe 'descendants of Wallaby::ResourcesController' do
    class CampervansController < Wallaby::ResourcesController; end
    class Campervan; end

    describe CampervansController do
      describe 'class methods ' do
        describe '.resources_name' do
          it 'returns resources name from controller name' do
            expect(described_class.resources_name).to eq 'campervans'
          end
        end

        describe '.model_class' do
          it 'returns model class' do
            expect(described_class.model_class).to eq Campervan
          end
        end
      end
    end
  end
end

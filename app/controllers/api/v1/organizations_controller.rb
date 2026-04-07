module Api
  module V1
    class OrganizationsController < ApplicationController
      def show
        authorize current_tenant, :show?
        render json: OrganizationSerializer.render_as_hash(current_tenant)
      end

      def update
        authorize current_tenant, :update?
        if current_tenant.update(organization_params)
          render json: OrganizationSerializer.render_as_hash(current_tenant)
        else
          render json: { errors: current_tenant.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def organization_params
        params.require(:organization).permit(:name)
      end
    end
  end
end

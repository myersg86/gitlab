class Groups::EpicsController < Groups::ApplicationController
  before_action :epic

  # TODO: consider reusing issue show
  def show
    respond_to do |format|
      format.html do
        render 'groups/ee/epics/show'
      end
      format.json do
        render json: serializer.represent(@epic)
      end
    end
  end

  def index
  end

  private

  def epic
    @epic ||= @group.epics.find(params[:id])
  end

  def serializer
    EpicSerializer.new(current_user: current_user)
  end
end

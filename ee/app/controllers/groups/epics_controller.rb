class Groups::EpicsController < Groups::ApplicationController
  include IssuableActions

  before_action :epic
  before_action :authorize_update_issuable!, only: :update

  skip_before_action :labels

  # TODO: we have 3 preview_markdown actions now (project, snippet, this) -> move into 1 if possible
  def preview_markdown
    result = PreviewMarkdownService.new(nil, current_user, params).execute

    render json: {
      body: view_context.markdown(result[:text], skip_project_check: true),
      references: {
        users: result[:users]
      }
    }
  end

  private

  def epic
    @issuable = @epic ||= @group.epics.find_by(iid: params[:id])
  end
  alias_method :issuable, :epic

  def epic_params
    params.require(:epic).permit(*epic_params_attributes)
  end

  def epic_params_attributes
    %i[
      title
      description
      start_date
      end_date
    ]
  end

  def serializer
    EpicSerializer.new(current_user: current_user)
  end

  def update_service
    Epics::UpdateService.new(nil, current_user, epic_params)
  end

  def show_view
    'groups/ee/epics/show'
  end
end

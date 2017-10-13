class Groups::EpicsController < Groups::ApplicationController
  before_action :epic

  # TODO permissions

  # TODO: consider reusing issue actions - some changes needed in controllers and perhaps in views as well
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

  def update
    # TODO what abbout spam, try to use issues action
    @epic = Epics::UpdateService.new(nil, current_user, epic_params).execute(epic)

    render_epic_json
  end

  # again - use issue action instead
  def realtime_changes
    Gitlab::PollingInterval.set_header(response, interval: 3_000)

    response = {
      title: view_context.markdown_field(@epic, :title),
      title_text: epic.title,
      description: view_context.markdown_field(@epic, :description),
      description_text: epic.description
    }

    # if @epic.edited?
    #   response[:updated_at] = @epic.updated_at
    #   response[:updated_by_name] = @epic.last_edited_by.name
    #   response[:updated_by_path] = user_path(@epic.last_edited_by)
    # end

    render json: response
  end

  # TODO: this will probably be similar as snippets preview although we have group
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
    @epic ||= @group.epics.find_by(iid: params[:id])

    # permissions check, 404 return
  end

  # a bit changed issue method should be possible to use here
  def render_epic_json
    if @epic.valid?
      render json: serializer.represent(@epic)
    else
      render json: { errors: @epic.errors.full_messages }, status: :unprocessable_entity
    end
  end

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
end

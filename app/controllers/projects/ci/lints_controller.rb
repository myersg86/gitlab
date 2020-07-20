# frozen_string_literal: true

class Projects::Ci::LintsController < Projects::ApplicationController
  before_action :authorize_create_pipeline!

  def show
  end

  def create
    @content = params[:content]
    result   = Gitlab::Ci::YamlProcessor.new_with_validation_errors(@content, yaml_processor_options)

    @status = result.valid?
    @errors = result.errors

    if result.valid?
      @config_processor = result.config
      @stages = @config_processor.stages
      @builds = @config_processor.builds
      @jobs = @config_processor.jobs
    end

    
    # # binding.pry
    
    # pp 'content', @content
    # pp 'result', result
    # pp 'status', @status
    # pp 'errrors', @errors
    # pp 'config processor', @config_processor
    # pp 'stages', @stages
    # pp 'builds', @builds
    # pp 'jobs', @jobs

    respond_to do |format|
      format.html { render :show }
      format.json do
        render json: { 
          valid: @status,
          errors: @errors,
          config_processor: @config_processor
        } 
      end
    end
  end

  private

  def yaml_processor_options
    {
      project: @project,
      user: current_user,
      sha: project.repository.commit.sha
    }
  end
end

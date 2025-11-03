class GroupsController < ApplicationController
  before_action :authenticate_user!

  def index
    @groups = current_user.groups
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    if @group.save
      @group.users << current_user
      redirect_to groups_path, notice: "Group created successfully."
    else
      flash.now[:alert] = @group.errors.full_messages.to_sentence
      render :new
    end
  end

  def join
    @group = Group.find_by(join_code: params[:join_code]&.strip&.upcase)
    if @group
      if @group.users.include?(current_user)
        redirect_to groups_path, alert: "You are already in this group."
      else
        @group.users << current_user
        redirect_to groups_path, notice: "Joined #{@group.name} successfully."
      end
    else
      redirect_to groups_path, alert: "Invalid join code."
    end
  end

  def show
    @group = current_user.groups.find(params[:id])
  end

  private

  def group_params
    params.require(:group).permit(:name)
  end
end

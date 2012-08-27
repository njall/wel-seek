class ExperimentalConditionsController < ApplicationController
  include Seek::FactorStudied
  include Seek::AnnotationCommon
  include Seek::AssetsCommon

  before_filter :login_required
  before_filter :find_and_auth_protocol
  before_filter :create_new_condition, :only=>[:index]
  before_filter :no_comma_for_decimal, :only=>[:create, :update]

  def index
    respond_to do |format|
      format.html
      format.xml {render :xml=>@protocol.experimental_conditions}
    end
  end

  def create
    @experimental_condition=ExperimentalCondition.new(params[:experimental_condition])
    @experimental_condition.protocol=@protocol
    @experimental_condition.protocol_version = params[:version]
    new_substances = params[:substance_autocompleter_unrecognized_items] || []
    known_substance_ids_and_types = params[:substance_autocompleter_selected_ids] || []
    substances = find_or_new_substances new_substances,known_substance_ids_and_types
    substances.each do |substance|
      @experimental_condition.experimental_condition_links.build(:substance => substance )
    end

    update_annotations(@experimental_condition, 'description') if try_block{!params[:annotation][:value].blank?}

    render :update do |page|
      if @experimental_condition.save
        page.insert_html :bottom,"condition_or_factor_rows",:partial=>"studied_factors/condition_or_factor_row",:object=>@experimental_condition,:locals=>{:asset => 'protocol', :show_delete=>true}
        page.visual_effect :highlight,"condition_or_factor_rows"
        # clear the _add_factor form
        page.call "autocompleters['substance_autocompleter'].deleteAllTokens"
        page[:add_condition_or_factor_form].reset
        page[:substance_condition_factor].hide
        page[:growth_medium_or_buffer_description].hide
      else
        page.alert(@experimental_condition.errors.full_messages)
      end
    end
  end

  def create_from_existing
    experimental_condition_ids = []
    new_experimental_conditions = []
    #retrieve the selected FSes
    params.each do |key, value|
       if key.match('checkbox_')
         experimental_condition_ids.push value.to_i
       end
    end
    #create the new FSes based on the selected FSes
    experimental_condition_ids.each do |id|
      experimental_condition = ExperimentalCondition.find(id)
      new_experimental_condition = ExperimentalCondition.new(:measured_item_id => experimental_condition.measured_item_id, :unit_id => experimental_condition.unit_id, :start_value => experimental_condition.start_value)
      new_experimental_condition.protocol=@protocol
      new_experimental_condition.protocol_version = params[:version]
      experimental_condition.experimental_condition_links.each do |ecl|
         new_experimental_condition.experimental_condition_links.build(:substance => ecl.substance)
      end
      params[:annotation] = {}
      params[:annotation][:value] = try_block{Annotation.for_annotatable(experimental_condition.class.name, experimental_condition.id).with_attribute_name('description').first.value.text}
      update_annotations(new_experimental_condition, 'description') if try_block{!params[:annotation][:value].blank?}

      new_experimental_conditions.push new_experimental_condition
    end
    #
    render :update do |page|
        new_experimental_conditions.each do  |ec|
          if ec.save
            page.insert_html :bottom,"condition_or_factor_rows",:partial=>"studied_factors/condition_or_factor_row",:object=>ec,:locals=>{:asset => 'protocol', :show_delete=>true}
          else
            page.alert("can not create factor studied: item: #{try_block{ec.substance.name}} #{ec.measured_item.title}, value: #{ec.start_value}}#{ec.unit.title}")
          end
        end
        page.visual_effect :highlight,"condition_or_factor_rows"
    end
  end

  def destroy
    @experimental_condition=ExperimentalCondition.find(params[:id])
    render :update do |page|
      if @experimental_condition.destroy
        page.visual_effect :fade, "condition_or_factor_row_#{@experimental_condition.id}"
        page.visual_effect :fade, "edit_condition_or_factor_#{@experimental_condition.id}_form"
      else
        page.alert(@experimental_condition.errors.full_messages)
      end
    end
  end

  def update
      @experimental_condition = ExperimentalCondition.find(params[:id])

      new_substances = params["#{@experimental_condition.id}_substance_autocompleter_unrecognized_items"] || []
      known_substance_ids_and_types = params["#{@experimental_condition.id}_substance_autocompleter_selected_ids"] || []
      substances = find_or_new_substances new_substances,known_substance_ids_and_types

      #delete the old experimental_condition_links
      @experimental_condition.experimental_condition_links.each do |ecl|
        ecl.destroy
      end

      #create the new experimental_condition_links
      experimental_condition_links = []
      substances.each do |substance|
        experimental_condition_links.push ExperimentalConditionLink.new(:substance => substance)
      end
      @experimental_condition.experimental_condition_links = experimental_condition_links

      update_annotations(@experimental_condition, 'description') if try_block{!params[:annotation][:value].blank?}

      render :update do |page|
        if  @experimental_condition.update_attributes(params[:experimental_condition])
          page.visual_effect :fade,"edit_condition_or_factor_#{@experimental_condition.id}_form"
          page.call "autocompleters['#{@experimental_condition.id}_substance_autocompleter'].deleteAllTokens"
          page.replace "condition_or_factor_row_#{@experimental_condition.id}", :partial => 'studied_factors/condition_or_factor_row', :object => @experimental_condition, :locals=>{:asset => 'protocol', :show_delete=>true}
        else
          page.alert(@experimental_condition.errors.full_messages)
        end
      end
  end


  private

  def find_and_auth_protocol
    begin
      protocol = Protocol.find(params[:protocol_id])
      if protocol.can_edit? current_user
        @protocol = protocol
        find_display_asset @protocol
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to protocols_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the protocol or you are not authorized to view it"
        format.html { redirect_to protocols_path }
      end
      return false
    end

  end

  def create_new_condition
    @experimental_condition=ExperimentalCondition.new(:protocol=>@protocol)
  end
end


class PlannedTripsController < TripAwareController
  
  # set the @planned_trip variable before any actions are invoked
  before_filter :get_planned_trip, :only => [:email, :show, :details, :unhide_all]

  TIME_FILTER_TYPE_SESSION_KEY = 'planned_trips_time_filter_type'
  
  def email
    Rails.logger.info "Begin email"
    email_addresses = params[:email][:email_addresses].split(/[ ,]+/)
    Rails.logger.info email_addresses.inspect
    email_addresses << current_user.email if user_signed_in? && params[:email][:send_to_me]
    email_addresses << current_traveler.email if assisting? && params[:email][:send_to_traveler]
    Rails.logger.info email_addresses.inspect
    from_email = user_signed_in? ? current_user.email : params[:email][:from]
    UserMailer.user_trip_email(email_addresses, @trip, "ARC OneClick Trip Itinerary", from_email).deliver
    respond_to do |format|
      format.html { redirect_to(@trip, :notice => "An email was sent to #{email_addresses.join(', ')}." ) }
      format.json { render json: @trip }
    end
  end
  
  def index

    # params needed for the subnav filters
    if params[:time_filter_type]
      @time_filter_type = params[:time_filter_type]
    else
       @time_filter_type = session[TIME_FILTER_TYPE_SESSION_KEY]
    end
    # if it is still not set use the default
    if @time_filter_type.nil?
      @time_filter_type = "0"
    end
    # store it in the session
    session[TIME_FILTER_TYPE_SESSION_KEY] = @time_filter_type

    # get the duration for this time filter
    duration = TimeFilterHelper.time_filter_as_duration(@time_filter_type)
    
    @planned_trips = @trips.planned_trips.created_between(duration.first, duration.last)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @planned_trips }
    end
    
  end

  # GET /trips/1
  # GET /trips/1.json
  def show
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @planned_trip }
    end
  end

  # GET /trips/1
  # GET /trips/1.json
  def details
    # TODO doesn't this need 
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @planned_trip }
    end
  end

  # called when the user wants to hide an option. Invoked via
  # an ajax call
  def hide

    itinerary = @planned_trip.itineraries.find(params[:id])
    if itinerary.nil?
      render text: 'Unable to remove itinerary.', status: 500
      return
    end

    itinerary.hidden = true
    if itinerary.save
      respond_to do |format|
        if itinerary
          format.js # hide.js.haml
        else
          render text: 'Unable to remove itinerary.', status: 500
        end
    end
  end

  def unhide_all
    @planned_trip.hidden_itineraries.each do |i|
      i.hidden = false
      i.save
    end
    redirect_to @planned_trip    
  end

protected

  def get_planned_trip
    
    planned_trip = @trip.planned_trips.find(params[:id])
    if planned_trip.nil?
    else
      @planned_trip = planned_trip
    end 

  end

end

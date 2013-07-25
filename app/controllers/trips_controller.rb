class TripsController < ApplicationController

  # GET /trips/1
  # GET /trips/1.json
  def show
    @trip = Trip.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trip }
    end
  end

  # GET /trips/new
  # GET /trips/new.json
  def new
    @trip = Trip.new
    # TODO User might be different if we are an agent
    @trip.owner = current_user || anonymous_user

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trip }
    end
  end

  # POST /trips
  # POST /trips.json
  def create
    @trip = Trip.new(params[:trip])
    @trip.owner = current_user || anonymous_user

    respond_to do |format|
      if @trip.save
        @trip.create_itineraries
        if @trip.has_valid_itineraries?
          flash[:notice] = t(:trip_was_successfully_created)
        else
          message = t(:trip_created_no_valid_options)
          details = @trip.itineraries.collect do |i|
            "<li>%s (%s)</li>" % [i.message, i.status]
          end
          message = message + '<ol>' + details.join + '</ol>'
          flash[:error] = message.html_safe
        end
        format.html { redirect_to @trip }
        format.json { render json: @trip, status: :created, location: @trip }
      else
        format.html { render action: "new" }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

end

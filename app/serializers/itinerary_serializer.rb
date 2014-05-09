class ItinerarySerializer < ActiveModel::Serializer
  include CsHelpers

  attributes :id, :missing_information, :mode, :mode_name, :service_name, :contact_information,
  :cost, :duration, :transfers, :start_time, :end_time, :legs, :service_window

  def mode
    object.mode.code rescue nil
  end

  def mode_name
    get_trip_summary_title(object)
  end

  def missing_information
    es = EligibilityService.new
    es.get_service_itinerary(object.service, object.trip_part.trip.user.user_profile, object.trip_part, :missing_info)
  end

  def contact_information
    case object.mode
    when Mode.taxi
      {
        text: (YAML.load(object.server_message).collect{|k| k['name'] + ': ' + k['phone']}.join(", ") rescue nil)
      }
    else      
      object.service.contact_information rescue nil
    end
  end

  def start_time
    tp = object.trip_part
    case object.mode      
    when Mode.taxi
      tp.is_depart ? tp.trip_time : (tp.trip_time - object.duration.seconds)
    when Mode.rideshare
      tp.is_depart ? tp.trip_time : nil
    else
      object.start_time
    end
  end

  def end_time
    tp = object.trip_part
    case object.mode      
    when Mode.taxi
      tp.is_depart ? (tp.trip_time + object.duration.seconds) : tp.trip_time
    when Mode.rideshare
      tp.is_depart ? nil : tp.trip_time
    else
      object.start_time
    end
  end

  def cost
    fare = object.cost || (object.service.fare_structures.first rescue nil)
    if fare.nil?
      {price: nil, comments: 'Unknown'} # TODO I18n
    else
      if fare.respond_to? :base
        {price: fare.base.to_f, comments: fare.desc}
      else
        {price: fare.to_f, comments: nil}
      end
    end
  end

  def legs
    legs = object.get_legs

    new_legs = []
    (0..legs.count-2).each do |n|
      leg =
        {
          type: legs[n].mode,
          description: I18n.t(:to) + ' '+ legs[n].end_place.name,
          start_time: legs[n].start_time,
          end_time: legs[n].end_time,
          start_place: "#{legs[n].start_place.lat},#{legs[n].start_place.lon}",
          end_place: "#{legs[n].end_place.lat},#{legs[n].end_place.lon}",
        }
      new_legs << leg
      if legs[n].end_time < legs[n+1].start_time
        new_leg =
          {
            type: 'WAIT',
            description: I18n.t(:to) + ' '+ legs[n].end_place.name,
            start_time: legs[n].end_time,
            end_time: legs[n+1].start_time,
            start_place: "#{legs[n+1].start_place.lat},#{legs[n+1].start_place.lon}",
            end_place: "#{legs[n+1].start_place.lat},#{legs[n+1].start_place.lon}",
          }
        new_legs << new_leg
      end

    end
    new_legs
  end

  def duration
    {
      # TODO I18n
      # omitting for now per discussion w/ Xudong
      # external_duration: , #": "String Opt", // (seconds) Textural description of duration, for display to users
      sortable_duration: object.duration, #": "Number Opt", // (seconds) For filtering purposes, not display
      total_walk_time: object.walk_time, #": "Number Opt", // (seconds) 
      total_walk_dist: object.walk_distance, #": "Number Opt", // (feet?) 
      total_transit_time: object.transit_time, #": "Number Opt", // (seconds) 
      total_wait_time: object.wait_time, #": "Number Opt", // (seconds) 
    }
  end

  def service_window
    case object.mode
    when Mode.paratransit
      object.service.service_window || 0
    else
      0
    end
  end

end

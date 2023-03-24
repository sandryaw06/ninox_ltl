"--CONVERT TO RED--";
function convert_to_red(str : text) do
	html("<div style=""background-color:#f5765d""> " + str + " </div>")
end;
"--CURRENT MONDAY--";
function current_monday() do
	today() - weekday(today())
end;
"--CURRENT FACTURATION WEEK START--";
function current_facturation_week_start() do
	today() - weekday(today()) - 6
end;
"--CURRENT FACTURATION WEEK END--";
function current_facturation_week_end() do
	today() - weekday(today())
end;
"--CURRENT COMISSION WEEK START--";
function current_comission_week_start() do
	today() - weekday(today()) - 6
end;
"--CURRENT COMISSION WEEK END--";
function current_comission_week_end() do
	today() - weekday(today())
end;
"--CURRENT COMISSION WEEK END--";
function current_comission_week_end() do
	today() - weekday(today())
end;
"--CURRENT TRUCK CURRENT LOCATION--";
function truck_current_location(truck : text) do
	let truck := first(select TrucksDB where truck_ = truck);
	if truck.location_ like "Home" or truck.location_ like "Hillsborough County, FL, 33610" or
			truck.location_ like "Sligh" or
		truck.location_ like "Lightning" then
		"In Yard"
	else
		if truck.location_ like "Hillsborough County, FL, 33619" then
			"Penske"
		else
			if truck.location_ like "Lake-Orient" then
				"Nextran"
			else
				truck.city_state_Location_
			end
		end
	end
end;
"--GET FULL NAME DRIVERS HOURS--";
function get_full_name_drivers_hours(truck : text) do
	let drivers_names_hrs := [""];
	let drivers := (select SamsaraDrivers where last_truck_reported_ = text(truck));
	for d in drivers do
		let name := d.name_on_system_;
		let hr := d.cycle_remaining_;
		drivers_names_hrs := array(drivers_names_hrs, [name + " (" + hr + ")"])
	end;
	join(drivers_names_hrs, "
		")
end;
"--GET DRIVERS HOURS--";
function get_drivers_hours(truck : text) do
	let drivers_names_hrs := [""];
	let drivers := (select SamsaraDrivers where last_truck_reported_ = text(truck)).cycle_remaining_;
	join(drivers, "/")
end;
"--GET WEEK SUMMARY--";
function get_week_summary(truck : number,f : date,t : date) do
	let fuels_week := sum((select 'Daily Fuel' where truck_ = truck and postDate_ >= f and postDate_ <= t).subTotal_);
	let miles_week := sum((select 'Daily Fuel' where truck_ = truck and postDate_ >= f).odoMiles_);
	let miles_start := (select 'Daily Fuel' where truck_ = truck and postDate_ = current_facturation_week_start()).odoMiles_;
	let gross_week := sum((select Loads where 'DEL Date' >= f and 'DEL Date' <= t and Truck = truck).Gross);
	let current_rpm := number(gross_week) / number(miles_week);
	let dif := number(miles_week) - number(miles_start);
	let driver_pay := sum((select DriverPay where number(TruckNumber_) = number(truck) and 'Out Date' <= t and 'Return Date' > f).'Week Payment');
	let truck_other_deduction := sum((select Facturacion where 'Truck#' = truck and From < f + 4 and To > t - 4).Expenses_nofuel_nodriverpay_);
	"Gross Week: " + gross_week + " / RPM: " + round(current_rpm, 2) +
	"
" +
	"Week Fuel: " +
	fuels_week +
	"
" +
	"Driver Pay: " +
	driver_pay +
	" / Other: " +
	format(number(round(number(truck_other_deduction), 2)), "$#,###.##") +
	"
" +
	"Net: " +
	format(number(round(number(gross_week) - number(fuels_week) - number(driver_pay) -
	number(truck_other_deduction), 2)), "$#,###.##")
end;
"--GENERATE GENERAL NOTES--";
function generate_general_notes(truck : text) do
	get_full_name_drivers_hours(text(truck))
end;
"--GET LOAD--";
function get_load(day_to_add : number,dispatch : number,f : date,trk : number) do
	let d1 := f + day_to_add;
	let d := dispatch;
	let tr := trk;
	let ht := convert_to_red(text(d1));
	let w := (select Loads where Dispatch = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and Truck = tr);
	if last(w.'PU Date') = d1 and first(w.'DEL Date') = d1 then
		concat("-> " + first(w.Delivery)) +
		"
" +
		concat(last(w.Origin) + " ->") +
		"
	" +
		get_drivers_hours(text(trk))
	else
		if w.'PU Date' = d1 then
			concat(w.Origin + " ->") +
			"
		" +
			get_drivers_hours(text(trk))
		else
			if w.'DEL Date' = d1 then
				concat("-> " + w.Delivery) +
				"
			" +
				get_drivers_hours(text(trk))
			else
				if w.'PU Date' <= d1 and w.'DEL Date' >= d1 then
					concat("In Transit") +
					"
				" +
					get_drivers_hours(text(trk))
				else
					if today() = d1 then
						if truck_current_location(text(trk)) = "In Yard" then
							"In Yard"
						else
							truck_current_location(text(trk)) +
							"
" +
							"Empty" +
							"

" +
							get_drivers_hours(text(trk))
						end
					else
						void
					end
				end
			end
		end
	end
end;
"--ADD LOAD--";
function add_load(from_ : date,d : number,trk : text) do
	let d1 := from_;
	let disp := d;
	let tr := number(trk);
	let w := cnt(select Loads where Dispatch = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and Truck = tr);
	let r := 0;
	"let w1 := Dispatch;";
	if w > 0 then
		let f := number(last(select Loads
					where number(Dispatch) = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and
					number(Truck) = number(tr)).'Id#');
		popupRecord(record(Loads,number(f)))
	else
		let check := dialog("Confirm Action", "Add a New Load? Please confirm.", ["Yes, create a new Load", "Cancel"]);
		if check = "Yes, create a new Load" then
			let q := (create Loads);
			r := number(q.Id);
			q.(Dispatch := d);
			q.(Truck := tr);
			q.('PU Date' := d1);
			popupRecord(record(Loads,number(r)))
		end
	end
end
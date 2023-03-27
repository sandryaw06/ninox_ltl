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
	if truck.location_ like "Home" or truck.location_ like "Hillsborough County, FL, 33610" or truck.location_ like "Sligh" or truck.location_ like "Lightning" then
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
function get_week_summary_gross(truck : number,f : date,t : date) do
	let gross_week := sum((select Loads where 'DEL Date' >= f and 'DEL Date' <= t and Truck = truck).Gross);
	number(gross_week)
end;
function get_week_summary_net(truck : number,f : date,t : date) do
	let gross_week := get_week_summary_gross(truck, f, t);
	let fuels_week := sum((select 'Daily Fuel' where truck_ = truck and postDate_ >= f and postDate_ <= t).subTotal_);
	let driver_pay := sum((select DriverPay where number(TruckNumber_) = number(truck) and 'Out Date' <= t and 'Return Date' > f).'Week Payment');
	let truck_other_deduction := sum((select Facturacion where 'Truck#' = truck and From < date(f) + 4 and To > date(t) - 4).Expenses_nofuel_nodriverpay_);
	number(round(number(gross_week) - number(fuels_week) - number(driver_pay) - number(truck_other_deduction), 2))
end;
"--TRUCK LOAD CALENDAR --";
function get_truck_loads_calendar(dispatch : number,f : date,t : date,r : number) do
	let truck := item(sort((select TrucksDB where dispatch_ = dispatch).truck_), r);
	let return_string := html("<div style=""color:black"">" + text(truck) + " </div>");
	let net := get_week_summary_net(truck, f, t);
	let gross := get_week_summary_gross(truck, f, t);
	text(truck)
end;
function get_truck_loads_calendar_html(dispatch : number,f : date,t : date,r : number) do
	let truck := item(sort((select TrucksDB where dispatch_ = dispatch).truck_), r);
	let return_string := html("<div style=""color:black"">" + text(truck) + " </div>");
	let net := get_week_summary_net(truck, f, t);
	let gross := get_week_summary_gross(truck, f, t);
	if number(net) <= 0 and number(gross) > 0 then
		return_string := html("<div style=""color:red"">" + text(truck) + " </div>")
	end;
	if net > 0 and gross > 0 then
		return_string := html("<div style=""color:green"">" + text(truck) + " </div>")
	end;
	return_string
end;
"--GET WEEK SUMMARY--";
"let q := Dispatch;";
"get_week_summary(number(q), date(from_), date(To_ + 1),0)";
function get_week_summary(dispatch : number,f : date,t : date,r : number) do
	let truck := item(sort((select TrucksDB where dispatch_ = dispatch).truck_), r);
	let fuels_week := sum((select 'Daily Fuel' where truck_ = truck and postDate_ >= f and postDate_ <= t).subTotal_);
	let miles_week := sum((select 'Daily Fuel' where truck_ = truck and postDate_ >= f).odoMiles_);
	let miles_start := (select 'Daily Fuel' where truck_ = truck and postDate_ = current_facturation_week_start()).odoMiles_;
	let gross := get_week_summary_gross(truck, f, t);
	let net := get_week_summary_net(truck, f, t);
	let current_rpm := number(gross) / number(miles_week);
	let dif := number(miles_week) - number(miles_start);
	let driver_pay := sum((select DriverPay where number(TruckNumber_) = number(truck) and 'Out Date' <= t and 'Return Date' > f).'Week Payment');
	let truck_other_deduction := sum((select Facturacion where 'Truck#' = truck and From < date(f) + 4 and To > date(t) - 4).Expenses_nofuel_nodriverpay_);
	let net_str := html("<div> <b> Gross Week:" + format(gross, "$#,###.##") + " / RPM: " + round(current_rpm, 2) + " </b> </div> <div> <b>Week Fuel: " + fuels_week + "</b></div> <div><b> Driver Pay: " + driver_pay + " / Other: " + format(number(round(number(truck_other_deduction), 2)), "$#,###.##") + "</b></div> <div style=""color:green""><b>" + format(net, "$#,###.##") + " </b> </div> ");
	if net < 0 then
		net_str := html("<div> <b> Gross Week:" + format(gross, "$#,###.##") + " / RPM: " + round(current_rpm, 2) + " </b> </div> <div> <b>Week Fuel: " + fuels_week + "</b></div> <div><b> Driver Pay: " + driver_pay + " / Other: " + format(number(round(number(truck_other_deduction), 2)), "$#,###.##") + "</b></div> <div style=""color:red""><b>" + format(net, "$#,###.##") + " </b> </div> ")
	end;
	net_str
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
		concat("-> " + first(w.Delivery)) + "
" + concat(last(w.Origin) + " ->") + "
	" + get_drivers_hours(text(trk))
	else
		if w.'PU Date' = d1 then
			concat(w.Origin + " ->") + "
		" + get_drivers_hours(text(trk))
		else
			if w.'DEL Date' = d1 then
				concat("-> " + w.Delivery) + "
			" + get_drivers_hours(text(trk))
			else
				if w.'PU Date' <= d1 and w.'DEL Date' >= d1 then
					concat("In Transit") + "
				" + get_drivers_hours(text(trk))
				else
					if today() = d1 then
						if truck_current_location(text(trk)) = "In Yard" then
							"In Yard"
						else
							truck_current_location(text(trk)) + "
" + "Empty" + "

" + get_drivers_hours(text(trk))
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
		let f := number(last(select Loads where number(Dispatch) = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and number(Truck) = number(tr)).'Id#');
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
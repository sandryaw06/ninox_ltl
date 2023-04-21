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
"-- WEEK PAID AFTER UPDATE ON PAYMENT APPROVAL--";
function update_week_paid_select_(weekpaid : boolean,wpaid : number,wtp : number,trk : number,disp : text,outd : date,ret : date,dayp : number,weekp : number,log : text) do
	if weekpaid = 1 then wpaid := wtp else wpaid := null end;
	let l := log;
	log := concat(today() + "Truck: " + trk + ", Dispatch: " + disp + ", Out Date: " + outd +
			", Return: " +
			ret +
			", Day Pay: " +
			dayp +
			"
" +
			l)
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
"-- NET ON HISTORIC SUMMARY--";
function net_on_historic_summary(truck : number,f : date) do
	let q := truck;
	let d := date(f) + 2;
	let n := sum((select Facturacion
				where number('Truck#') = number(q) and date(From) < date(d) and date(To) > date(d) and
				number(total_gross_facturado) > 0).Net_);
	if n != 0 then number(n) else void end
end;
"--GET DRIVERS HOURS--";
function get_drivers_hours(truck : text) do
	let drivers_names_hrs := [""];
	let drivers := (select SamsaraDrivers where last_truck_reported_ = text(truck)).cycle_remaining_;
	join(drivers, "/")
end;
function get_week_summary_gross(truck : number,f : date,t : date) do
	let trn := last((select TrucksDB where truck_ = number(truck)).Id);
	let gross_week := sum((select Loads where 'DEL Date' >= f and 'DEL Date' <= t and TrucksDB = trn).Gross);
	number(gross_week)
end;
function get_week_loads_miles(truck : number,f : date,t : date) do
	let trn := last((select TrucksDB where truck_ = number(truck)).Id);
	let week_miles := sum((select Loads where 'DEL Date' >= f and 'DEL Date' <= t and TrucksDB = trn).Miles);
	number(week_miles)
end;
function get_week_summary_net(truck : number,f : date,t : date) do
	let gross_week := get_week_summary_gross(truck, f, t);
	let fuels_week := sum((select 'Daily Fuel' where truck_ = truck and postDate_ >= f and postDate_ <= t).subTotal_);
	let driver_pay := sum((select DriverPay where number(TruckNumber_) = number(truck) and 'Out Date' <= t and 'Return Date' > f).'Week Payment');
	let truck_other_deduction := sum((select Facturacion where 'Truck#' = truck and From < date(f) + 4 and To > date(t) - 4).Expenses_nofuel_nodriverpay_);
	let truck_percent := (select Facturacion where 'Truck#' = truck and From < date(f) + 4 and To > date(t) - 4).'%AppliedSaved';
	number(round(number(gross_week) - number(fuels_week) - number(driver_pay) -
	number(truck_other_deduction), 2))
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
	let driver_pay_date := last(select DriverPay where TruckNumber_ = truck and DriverInTruck = "Driver in Truck").'Return Day:';
	let result := "";
	if date(driver_pay_date) >= date(f) and date(driver_pay_date) <= date(t) then
		result := "<div style=""color:black"">" + text(driver_pay_date) + " </div>"
	end;
	let return_string := html("<div style=""color:black"">" + text(truck) + "<br><p style='font-size:2vw;'>" +
		result +
		"<p> </div>");
	let net := get_week_summary_net(truck, f, t);
	let gross := get_week_summary_gross(truck, f, t);
	if number(net) <= 0 and number(gross) > 0 then
		return_string := html("<div style=""color:red"">" + text(truck) + "<br><p style='font-size:2vw;'>" +
			result +
			"</p> </div>")
	end;
	if net > 0 and gross > 0 then
		return_string := html("<div style=""color:green"">" + text(truck) + "<br><p style='font-size:2vw;'>" +
			result +
			"</p> </div>")
	end;
	return_string
end;
"--GET WEEK SUMMARY--";
"let q := Dispatch;";
"get_week_summary(number(q), date(from_), date(To_ + 1),0)";
function get_week_summary(dispatch : number,f : date,t : date,r : number) do
	f := f + 1;
	let truck := item(sort((select TrucksDB where dispatch_ = dispatch).truck_), r);
	if truck > 0 then
		let fuels_week := sum((select 'Daily Fuel' where truck_ = truck and postDate_ >= f and postDate_ < t).subTotal_);
		let miles_week := get_week_loads_miles(truck, f, t);
		let miles_start := (select 'Daily Fuel' where truck_ = truck and postDate_ = current_facturation_week_start()).odoMiles_;
		let gross := round(get_week_summary_gross(truck, f, t), 2);
		let net := get_week_summary_net(truck, f, t);
		let current_rpm := number(gross) / number(miles_week);
		let dif := number(miles_week) - number(miles_start);
		let driver_pay := 2 *
			last((select DriverPay where number(TruckNumber_) = number(truck) and 'Out Date' <= t and 'Return Date' > f).'Week Payment');
		let truck_other_deduction := sum((select Facturacion where 'Truck#' = truck and From < date(f) + 4 and To > date(t) - 4).Expenses_nofuel_nodriverpay_);
		let truck_percent := (select FixedPayment where Truck = truck).'% Applied';
		let net_2 := gross * number(truck_percent) / 100 - fuels_week - driver_pay -
			truck_other_deduction;
		let net_str := html("<div> <b> Gross Week:" + format(gross, "$#,###.##") + " / RPM: " +
			round(current_rpm, 2) +
			" </b> </div> <div> <b>Week Fuel: " +
			fuels_week +
			"</b></div> <div><b> Driver Pay: " +
			driver_pay +
			" / Other: " +
			format(number(round(number(truck_other_deduction), 2)), "$#,###.##") +
			"</b></div> <div style=""color:green""><b>" +
			format(number(round(number(net_2), 2)), "$#,###.##") +
			" </b> </div> ");
		if net < 0 then
			net_str := html("<div> <b> Gross Week:" + format(gross, "$#,###.##") + " / RPM: " +
				round(current_rpm, 2) +
				" </b> </div> <div> <b>Week Fuel: " +
				fuels_week +
				"</b></div> <div><b> Driver Pay: " +
				driver_pay +
				" / Other: " +
				format(number(round(number(truck_other_deduction), 2)), "$#,###.##") +
				"</b></div> <div style=""color:red""><b>" +
				format(number(round(number(net_2), 2)), "$#,###.##") +
				" </b> </div> ")
		end;
		net_str
	else
		void
	end
end;
"--GENERATE GENERAL NOTES--";
function generate_general_notes(truck : text) do
	get_full_name_drivers_hours(text(truck))
end;
"--GET LOAD--";
function get_load(day_to_add : number,dispatch : number,f : date,trk : number) do
	if trk > 10 then
		let d1 := f + day_to_add;
		let d := dispatch;
		let tr := trk;
		let ht := convert_to_red(text(d1));
		let trn := last((select TrucksDB where truck_ = number(trk)).Id);
		let w := (select Loads where dispatch_ = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and TrucksDB = trn);
		let status := text(last((select Load_Status
					where truck_ = trk and dispatch_number_ = d and last(w.'Status From') <= d1 and
					last(w.'Status To') >= d1).status_));
		let status_html := "<div style=""background-color:green""> " + status + " </div>";
		switch status do
		case "Canceled":
			(status_html := "<div style=""background-color:red""> " + status + " </div>")
		case "Resetting":
			(status_html := "<div style=""background-color:yellow""> " + status + " </div>")
		case "Breakdown":
			(status_html := "<div style=""background-color:orange""> " + status + " </div>")
		case "Stoped":
			(status_html := "<div style=""background-color:grey""> " + status + " </div>")
		end;
		let flags := "";
		if last(w.'PU Date') = d1 and first(w.'DEL Date') = d1 then
			flags := "<div>->" + first(w.Delivery) + "</div><div><b>" + first(w).Gross +
				"</b></div></b><div>" +
				last(w.Origin) +
				" -></div>"
		else
			if w.'PU Date' = d1 then
				flags := "<div>" + w.Origin + " -></div>"
			else
				if w.'DEL Date' = d1 then
					flags := "<div> ->" + w.Delivery + "</div><div><b>" + w.Gross + "</b></div>"
				else
					if w.'PU Date' <= d1 and w.'DEL Date' >= d1 then
						flags := "<div> In Transit </div> "
					end
				end
			end
		end;
		let driver_hr := "";
		if today() = d1 then
			driver_hr := "<div>" + get_drivers_hours(text(trk)) + "</div> "
		end;
		let location_truck := "";
		if today() = d1 then
			if truck_current_location(text(trk)) = "In Yard" then
				location_truck := "In Yard"
			else
				location_truck := "<div>" + truck_current_location(text(trk)) + "</div><div> Empty</div> "
			end
		end;
		html("<div>" + flags + status_html + driver_hr + location_truck + "</div>")
	else
		void
	end
end;
"--ADD LOAD--";
function add_load(from_ : date,d : number,trk : text) do
	let d1 := from_;
	let disp := d;
	let tr := number(trk);
	let trn := last((select TrucksDB where truck_ = number(trk)).Id);
	let w := cnt(select Loads where dispatch_ = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and TrucksDB = trn);
	let last_del_day := cnt(select Loads where dispatch_ = d and 'DEL Date' = d1 and TrucksDB = trn);
	let more_loads_future := cnt(select Loads where dispatch_ = d and 'PU Date' >= d1 and TrucksDB = trn);
	let r := 0;
	"let w1 := Dispatch;";
	if w > 0 then
		if last_del_day = 1 and more_loads_future = 0 then
			let check := dialog("Confirm Action", "Add a New Load or See last load Please confirm.", ["Open Load", "Create a new Load", "Cancel"]);
			if check = "Open Load" then
				let f := number(last(select Loads
							where number(dispatch_) = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and
							number(TrucksDB) = number(trn)).'Id#');
				popupRecord(record(Loads,number(f)))
			else
				if check = "Create a new Load" then
					let q := (create Loads);
					r := number(q.Id);
					q.(dispatch_ := d);
					q.(TrucksDB := trn);
					q.('PU Date' := d1);
					popupRecord(record(Loads,number(r)))
				end
			end
		else
			let f := number(last(select Loads
						where number(dispatch_) = d and 'PU Date' <= d1 and 'DEL Date' >= d1 and
						number(TrucksDB) = number(trn)).'Id#');
			popupRecord(record(Loads,number(f)))
		end
	else
		let check := dialog("Confirm Action", "Add a New Load? Please confirm.", ["Yes, create a new Load", "Cancel"]);
		if check = "Yes, create a new Load" then
			let q := (create Loads);
			r := number(q.Id);
			q.(dispatch_ := d);
			q.(TrucksDB := trn);
			q.('PU Date' := d1);
			popupRecord(record(Loads,number(r)))
		end
	end
end;

function open_facturation(truck:text, from_: date, to_: date) do
	let f := date(from_) + 2;
	let t := date(date(to_) + 2);
	let fac := first(select Facturacion where Truck_ = truck and From = f and To = t);
	popupRecord(fac)

end
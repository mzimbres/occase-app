#!/bin/bash

DATA='{"notification": {"body": "This is a message","title": "Marcelo"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "eMkcLmwSSBeWXS_YEB-b_R:APA91bG2pyrDVr0BBoya0rQET0vfwTVE3aTeQsoqsxVMK70ypm6aaa-pNdX9uQ5BgEsoQGuVoe-EpeePJB8Q7XUfTvrTlgtRW8HSZ3qOaxotFUSaq8JqrgRtummIOnMFYUGqtg-sMP8Y"}'
curl https://fcm.googleapis.com/fcm/send -H "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization: key=AAAAKavk7EY:APA91bEtq36uuNhvGSHu8hEE-EKNr3hsgso7IvDOWCHIZ6h_8LXPLz45EC3gxHUPxKxf3254TBM1bNxBby_8xP4U0pnsRh4JjV4uo4tbdBe2sSNrzZWoqTgcCTqmk3fIn3ltiJp3HKx2"


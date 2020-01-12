#!/bin/bash

DATA='{"notification": {"body": "This is a message","title": "Marcelo"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "eT0y6_6aOjA:APA91bGd3sR0wTO3TTTU6ewtjvBD-KNg106MGLxX8plJSYlVcCe_FF9Q30NjHOTSlDz-7dpMDezCDcCuc3kescPB20qvuU7jSiQqpno6kGiaY3o7MtlJDKzPFwA484jsOBKHC7N4slB_"}'
curl https://fcm.googleapis.com/fcm/send -H "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization: key=AAAAKavk7EY:APA91bEtq36uuNhvGSHu8hEE-EKNr3hsgso7IvDOWCHIZ6h_8LXPLz45EC3gxHUPxKxf3254TBM1bNxBby_8xP4U0pnsRh4JjV4uo4tbdBe2sSNrzZWoqTgcCTqmk3fIn3ltiJp3HKx2"


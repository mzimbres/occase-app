#!/bin/bash

DATA='{"notification": {"body": "This is a message","title": "Marcelo"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "cYiBNmqQzHk:APA91bE0BZd2aWs2jrV0wrMfzO3N2g59MINJQpU5cDbc4HV_-jphafdB4A9HwZtdIOzoagmMIJRSJxVfSnwhEasjdYxXCFTCT0-5efRjzXza_wvMojwciP9xD0y1PFMq_zrgx1W9HxGz"}'
curl https://fcm.googleapis.com/fcm/send -H "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization: key=AAAAKavk7EY:APA91bEtq36uuNhvGSHu8hEE-EKNr3hsgso7IvDOWCHIZ6h_8LXPLz45EC3gxHUPxKxf3254TBM1bNxBby_8xP4U0pnsRh4JjV4uo4tbdBe2sSNrzZWoqTgcCTqmk3fIn3ltiJp3HKx2"


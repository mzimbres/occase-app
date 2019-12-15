#!/bin/bash

DATA='{"notification": {"body": "this is a body","title": "this is a title"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "d0eKubrV4aA:APA91bHXaV0r8uxQM99TDnsbDTSCm5rVf0IqthN9JMD-4MrFuK1iexvcGx2HcCuJ6BQ0N4D0EGhS3Zvnuj0dvwWPB7nuGREhdQVDnyn5LnepJPKWNasu1qwDAIw0R3eiUIWzro2g93dz"}'
curl https://fcm.googleapis.com/fcm/send -H "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization: key=AAAAKavk7EY:APA91bEtq36uuNhvGSHu8hEE-EKNr3hsgso7IvDOWCHIZ6h_8LXPLz45EC3gxHUPxKxf3254TBM1bNxBby_8xP4U0pnsRh4JjV4uo4tbdBe2sSNrzZWoqTgcCTqmk3fIn3ltiJp3HKx2"


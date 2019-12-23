#!/bin/bash

DATA='{"notification": {"body": "This is a message","title": "Marcelo"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "eiWCQ4PyCsU:APA91bHWjrY0gBM3tU5ORAaSqD-3KPVZ-c4jhSeB9e9j_1KQ4GWIRTMxSn_LDEomT8a4Z05Sg29InJOXYESrfYQ7OlwRAfMM7Ib_UmDujVOZYZB80kaJyrPWzHSeCSQf2gyl-2nMQR8H"}'
curl https://fcm.googleapis.com/fcm/send -H "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization: key=AAAAKavk7EY:APA91bEtq36uuNhvGSHu8hEE-EKNr3hsgso7IvDOWCHIZ6h_8LXPLz45EC3gxHUPxKxf3254TBM1bNxBby_8xP4U0pnsRh4JjV4uo4tbdBe2sSNrzZWoqTgcCTqmk3fIn3ltiJp3HKx2"


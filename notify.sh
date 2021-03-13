#!/bin/bash

DATA='{"notification": {"body": "This is a message","title": "Marcelo"}, "priority": "high", "data": {"click_action": "FLUTTER_NOTIFICATION_CLICK", "id": "1", "status": "done"}, "to": "dpv7_-a7Z6QodtFhIpJJSh:APA91bGO-waPFcH5_uGL84QcD8JEqbCGT-qF4XughM5H3ciL9ypuN6LKjm0RnRWinNSe_zEFBn2DnlA8awJ5Y97a7ECQoqx0qSayGWGEbh-cpNfl0BsdJVMOvd6FKIF4veKuQnL63nKt"}'
curl https://fcm.googleapis.com/fcm/send -H "Content-Type:application/json" -X POST -d "$DATA" -H "Authorization: key=AAAAKavk7EY:APA91bEtq36uuNhvGSHu8hEE-EKNr3hsgso7IvDOWCHIZ6h_8LXPLz45EC3gxHUPxKxf3254TBM1bNxBby_8xP4U0pnsRh4JjV4uo4tbdBe2sSNrzZWoqTgcCTqmk3fIn3ltiJp3HKx2"


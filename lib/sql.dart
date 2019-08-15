final String createPostsTable =
'''
CREATE TABLE posts
( id INTEGER
, from_ TEXT
, nick TEXT
, channel TEXT
, ex_details TEXT
, in_details TEXT
, date INTEGER
, pin_date INTEGER
, status INTEGER
, description TEXT
, price INTEGER)
''';

final String updatePostStatus =
'''
UPDATE posts SET status = ? WHERE id = ?
''';

final String updatePostOnAck =
'''
UPDATE posts
SET status = ?,
    id = ?,
    date = ?
WHERE rowid = ?
''';

final String updatePostPinDate =
'''
UPDATE posts SET pin_date = ? WHERE id = ?
''';

final String deletePost =
'''
DELETE FROM posts WHERE id = ?
''';

final String loadPosts =
'''
SELECT rowid, * FROM posts
''';

//___________________________________________________________
final String createConfig =
'''
CREATE TABLE config
( app_id TEXT PRIMARY KEY
, app_pwd TEXT
, nick TEXT
, last_post_id INTEGER
, last_seen_post_id INTEGER
, show_dialog_on_select_post TEXT
, show_dialog_on_del_post TEXT)
''';

final String updateNick =
'''
UPDATE config SET nick = ?
''';

final String updateLastPostId =
'''
UPDATE config SET last_post_id = ?
''';

final String updateLastSeenPostId =
'''
UPDATE config SET last_seen_post_id = ?
''';

final String updateShowDialogOnSelectPost =
'''
UPDATE config SET show_dialog_on_select_post = ?
''';

final String updateShowDialogOnDelPost =
'''
UPDATE config SET show_dialog_on_del_post = ?
''';

//___________________________________________________________

final String createChatStatus =
'''
CREATE TABLE chat_status
( post_id INTEGER
, user_id TEXT
, date INTEGER
, pin_date INTEGER
, nick TEXT
, app_ack_read_end INTEGER
, app_ack_received_end INTEGER
, server_ack_end INTEGER
, chat_length INTEGER
, n_unread_msgs INTEGER
, last_chat_item TEXT
, FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
, UNIQUE(post_id, user_id)
)
''';

final String insertChatStOnPost =
'''
INSERT INTO chat_status VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''';

final String insertOrReplaceChatOnPost =
'''
INSERT OR REPLACE INTO chat_status VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''';

final String selectChatStatusItem =
'''
SELECT * FROM chat_status WHERE post_id = ?
''';

final String deleteChatStElem =
'''
DELETE FROM chat_status WHERE post_id = ? AND user_id == ?
''';

final String updateServerAckEnd =
'''
UPDATE chat_status SET server_ack_end = ?
WHERE post_id = ? AND user_id == ?
''';

final String updateAppAckReceivedEnd =
'''
UPDATE chat_status SET app_ack_received_end = ?
WHERE post_id = ? AND user_id == ?
''';

final String updateAppAckReadEnd =
'''
UPDATE chat_status SET app_ack_read_end = ?
WHERE post_id = ? AND user_id == ?
''';

final String updateNUnreadMsgs =
'''
UPDATE chat_status SET n_unread_msgs = ?
WHERE post_id = ? AND user_id == ?
''';

//___________________________________________________________

final String createChats =
'''
CREATE TABLE chats
( post_id INTEGER
, user_id TEXT
, type INTEGER
, date INTEGER
, body TEXT
, FOREIGN KEY (post_id, user_id)
  REFERENCES chat_status (post_id, user_id) ON DELETE CASCADE
)
''';

final String insertChatMsg =
'''
INSERT INTO chats VALUES (?, ?, ?, ?, ?)
''';

//___________________________________________________________

final String creatOutChatTable =
'''
CREATE TABLE out_chat_msg_queue
( is_chat INTEGER
, payload TEXT)
''';

final String deleteOutChatMsg =
'''
DELETE FROM out_chat_msg_queue WHERE rowid = ?
''';

final String insertOutChatMsg =
'''
INSERT INTO out_chat_msg_queue VALUES (?, ?)
''';

final String loadOutChats =
'''
SELECT rowid, * FROM out_chat_msg_queue
''';

//___________________________________________________________________
// The menu table.

final String createMenuTable =
'''
CREATE TABLE menu
( code TEXT
, depth INTEGER
, leaf_reach INTEGER
, name TEXT
, idx INTEGER
, PRIMARY KEY (code, idx)
)
''';

final String insertMenuElem =
'''
INSERT INTO menu VALUES (?, ?, ?, ?, ?)
''';

final String updateLeafReach =
'''
UPDATE menu SET leaf_reach = ? WHERE code = ? AND idx = ?
''';


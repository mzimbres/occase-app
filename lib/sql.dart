final String createPostsTable =
'''
CREATE TABLE posts
( id INTEGER
, body TEXT
, date INTEGER
, pin_date INTEGER
, status INTEGER)
''';

final String updatePostStatus =
'''
UPDATE posts SET status = ? WHERE id = ?
''';

final String updatePostPinDate =
'''
UPDATE posts SET pin_date = ? WHERE id = ?
''';

final String delPostWithId =
'''
DELETE FROM posts WHERE id = ?
''';

final String loadPosts =
'''
SELECT rowid, * FROM posts
''';

final String clearPosts =
'''
DELETE FROM posts WHERE status = ?
''';

//___________________________________________________________

final String createConfig = 'CREATE TABLE config (cfg TEXT)';
final String updateConfig = 'UPDATE config SET cfg = ? WHERE rowid = ?' ;
final String readConfig =   'SELECT * FROM config';
final String insertConfig = 'INSERT INTO config (cfg) VALUES (?)';

//___________________________________________________________

final String createChatStatus =
'''
CREATE TABLE chat_status
( post_id TEXT
, user_id TEXT
, date INTEGER
, pin_date INTEGER
, nick TEXT
, avatar TEXT
, chat_length INTEGER
, n_unread_msgs INTEGER
, FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE
, UNIQUE(post_id, user_id)
)
''';

final String insertChatStOnPost =
'''
INSERT INTO chat_status VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''';

final String insertOrReplaceChatOnPost =
'''
INSERT OR REPLACE INTO chat_status VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''';

final String selectChatStatusItem =
'''
SELECT * FROM chat_status WHERE post_id = ?
''';

final String deleteChatStElem =
'''
DELETE FROM chat_status WHERE post_id = ? AND user_id == ?
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
( post_id TEXT
, user_id TEXT
, peer_rowid INTEGER
, is_redirected INTEGER
, date INTEGER
, msg TEXT
, refers_to INTEGER
, status INTEGER
, FOREIGN KEY (post_id, user_id)
  REFERENCES chat_status (post_id, user_id) ON DELETE CASCADE
)
''';

final String selectChats =
'''
SELECT * FROM chats WHERE post_id = ? AND user_id == ?
''';

final String updateAckStatus =
'''
UPDATE chats SET status = ? WHERE rowid = ?
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


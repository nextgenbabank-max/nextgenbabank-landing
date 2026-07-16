-- Phase: Phân loại chủ đề tin nhắn chat học viên-mentor (nullable, chat cũ hiển thị "Khác")

alter table messages
  add column if not exists topic text
    check (topic in ('assignment', 'lesson', 'schedule', 'feedback', 'document', 'other'));

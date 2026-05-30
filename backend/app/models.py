from django.db import models


class ChatMessage(models.Model):

    ROLE_CHOICES = (
        ("user", "User"),
        ("assistant", "Assistant"),
    )

    user_id = models.BigIntegerField()

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES
    )

    message = models.TextField()

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "chat_messages"

    def __str__(self):

        return f"{self.user_id} - {self.role}"
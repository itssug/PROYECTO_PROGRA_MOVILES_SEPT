from .models import ChatMessage


class MemoryService:

    def save_message(self, user, role, message):

        ChatMessage.objects.create(
            user_id=user.id,
            role=role,
            message=message
        )

    def get_recent_history(self, user, limit=10):

        messages = ChatMessage.objects.filter(
            user_id=user.id
        ).order_by("-created_at")[:limit]

        history = []

        for msg in reversed(messages):

            history.append({
                "role": msg.role,
                "message": msg.message
            })

        return history
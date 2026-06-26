from .models import ChatMessage


class MemoryService:

    def save_message(self, user_id: int, role: str, message: str):
        # Recibe user_id directamente (int), no el objeto User
        ChatMessage.objects.create(
            user_id=user_id,
            role=role,
            message=message,
        )

    def get_recent_history(self, user_id: int, limit: int = 10) -> list:
        messages = (
            ChatMessage.objects
            .filter(user_id=user_id)
            .order_by("-created_at")[:limit]
        )

        return [
            {"role": msg.role, "message": msg.message}
            for msg in reversed(list(messages))
        ]
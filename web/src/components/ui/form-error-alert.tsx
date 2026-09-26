import { TriangleAlert, X } from "lucide-react";

interface FormErrorAlertProps {
    message: string | null;
    onDismiss: () => void;
}

export function FormErrorAlert({ message, onDismiss }: FormErrorAlertProps) {
    if (!message) return null;

    return (
        <div className="fixed inset-x-0 top-16 z-50 flex justify-center px-4 pointer-events-none">
            <div
                role="alert"
                className="pointer-events-auto flex w-full max-w-2xl items-start gap-3 rounded-lg border border-destructive/30 bg-background p-3 shadow-lg motion-safe:animate-in motion-safe:fade-in-0 motion-safe:slide-in-from-top-2 motion-safe:duration-200"
            >
                <TriangleAlert className="mt-0.5 h-4 w-4 shrink-0 text-destructive" aria-hidden="true" />
                <p className="flex-1 min-w-0 break-words text-sm text-destructive">{message}</p>
                <button
                    type="button"
                    onClick={onDismiss}
                    aria-label="Dismiss"
                    className="shrink-0 rounded-md p-0.5 text-muted-foreground transition-colors hover:text-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                >
                    <X className="h-4 w-4" aria-hidden="true" />
                </button>
            </div>
        </div>
    );
}

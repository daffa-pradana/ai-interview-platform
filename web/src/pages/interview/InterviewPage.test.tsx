import { describe, expect, it, vi } from "vitest";
import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import InterviewPage from "./InterviewPage";
import { sessionsApi } from "@/services/sessions";
import { useAudioWebSocket } from "@/hooks/useAudioWebSocket";

vi.mock("@/services/sessions", () => ({
    sessionsApi: { getCandidateInfo: vi.fn() },
}));

vi.mock("@/components/HardwareCheck", () => ({
    default: ({ onStart }: { onStart: () => void }) => <button onClick={onStart}>Start Interview</button>,
}));

vi.mock("@/hooks/useAudioCapture", () => ({
    useAudioCapture: () => ({ start: vi.fn(), stop: vi.fn(), mute: vi.fn(), unmute: vi.fn() }),
}));

vi.mock("@/hooks/useAudioPlayback", () => ({
    useAudioPlayback: () => ({
        playChunk: vi.fn(), stop: vi.fn(), scheduleAfterPlayback: vi.fn(), waitForDrain: vi.fn(), cancelDrain: vi.fn(),
    }),
}));

vi.mock("@/hooks/useAudioWebSocket", () => ({
    useAudioWebSocket: vi.fn(() => ({
        connect: vi.fn(), send: vi.fn(), sendJson: vi.fn(), disconnect: vi.fn(), connectionState: "disconnected",
    })),
}));

describe("InterviewPage", () => {
    it("shows the server's message as final when the interview cannot start", async () => {
        vi.mocked(sessionsApi.getCandidateInfo).mockResolvedValue({
            data: { session_id: 1, session_status: "pending", role_title: "Jr. Frontend Engineer", time_limit_min: 10 },
        } as never);
        render(
            <MemoryRouter initialEntries={["/interview/test-token"]}>
                <Routes>
                    <Route path="/interview/:token" element={<InterviewPage />} />
                </Routes>
            </MemoryRouter>,
        );

        await userEvent.click(await screen.findByRole("button", { name: "Start Interview" }));
        const options = vi.mocked(useAudioWebSocket).mock.lastCall![0];
        act(() => {
            options.onFatalError?.("This interview can't start right now. Please contact the person who invited you.");
            options.onStateChange("failed");
        });

        expect(screen.getByText("This interview can't start right now. Please contact the person who invited you.")).toBeInTheDocument();
        expect(screen.queryByText("Interview Complete")).not.toBeInTheDocument();
        expect(screen.queryByText(/reconnecting/i)).not.toBeInTheDocument();
    });
});

import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import AssessmentEditPage from "./AssessmentEditPage";
import { assessmentsApi } from "@/services/assessments";

vi.mock("@/services/assessments", () => ({
    assessmentsApi: { get: vi.fn(), update: vi.fn() },
}));

const anchors = {
    scope_include: "Test scope",
    l1_anchor: "Level 1 behaviour", l2_anchor: "Level 2 behaviour", l3_anchor: "Level 3 behaviour",
    l4_anchor: "Level 4 behaviour", l5_anchor: "Level 5 behaviour",
};

const savedSkills = [
    { id: 5, skill_id: null, skill_label: "RESTful API Design", is_custom: true, expected_level: 3, display_order: 0, ...anchors },
    { id: 7, skill_id: null, skill_label: "Ruby on Rails", is_custom: true, expected_level: 2, display_order: 1, ...anchors },
];

function renderEditPage() {
    render(
        <MemoryRouter initialEntries={["/assessments/2/edit"]}>
            <Routes>
                <Route path="/assessments/:id/edit" element={<AssessmentEditPage />} />
            </Routes>
        </MemoryRouter>,
    );
}

describe("AssessmentEditPage", () => {
    beforeEach(() => {
        vi.mocked(assessmentsApi.get).mockResolvedValue({
            data: { assessment: { id: 2, name: "Jr. Backend Engineer", time_limit_min: 30, skills: savedSkills } },
        } as never);
        vi.mocked(assessmentsApi.update).mockResolvedValue({ data: {} } as never);
    });

    it("sends _destroy for a saved skill the assessor removed", async () => {
        renderEditPage();

        const removeButtons = await screen.findAllByRole("button", { name: "Remove skill" });
        await userEvent.click(removeButtons[1]);
        await userEvent.click(screen.getByRole("button", { name: "Save Changes" }));

        await waitFor(() => expect(assessmentsApi.update).toHaveBeenCalled());
        const payload = vi.mocked(assessmentsApi.update).mock.calls[0][1];
        expect(payload.assessment_skills_attributes).toContainEqual({ id: 7, _destroy: true });
        expect(payload.assessment_skills_attributes).toContainEqual(expect.objectContaining({ id: 5 }));
    });
});

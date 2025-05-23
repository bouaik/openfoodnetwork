/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import tag_list_input_controller from "../../../app/components/tag_list_input_component/tag_list_input_controller";

describe("TagListInputController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("tag-list-input-component--tag-list-input", tag_list_input_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="tag-list-input-component--tag-list-input">
        <input 
          value="tag 1,tag 2,tag 3" 
          data-tag-list-input-component--tag-list-input-target="tagList" 
          type="hidden" 
          name="variant_tag_list" id="variant_tag_list"
        >
        <div class="tags-input">
          <div class="tags">
            <ul class="tag-list" data-tag-list-input-component--tag-list-input-target="list">
              <template data-tag-list-input-component--tag-list-input-target="template">
                <li class="tag-item">
                  <div class="tag-template">
                  <span></span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input-component--tag-list-input#removeTag"
                  >✖</a>
                  </div>
                </li>
              </template>
              <li class="tag-item">
                <div class="tag-template">
                  <span>tag 1</span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input-component--tag-list-input#removeTag"
                  >✖</a>
                </div>
              </li>
              <li class="tag-item">
                <div class="tag-template">
                  <span>tag 2</span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input-component--tag-list-input#removeTag"
                  >✖</a>
                </div>
              </li>
              <li class="tag-item">
                <div class="tag-template">
                  <span>tag 3</span>
                  <a 
                    class="remove-button" 
                    data-action="click->tag-list-input-component--tag-list-input#removeTag"
                  >✖</a>
                </div>
              </li>
            </ul>
            <input 
              type="text" 
              name="variant_add_tag" 
              id="variant_add_tag" 
              placeholder="Add a tag" 
              data-action="keydown.enter->tag-list-input-component--tag-list-input#addTag keyup->tag-list-input-component--tag-list-input#filterInput" data-tag-list-input-component--tag-list-input-target="newTag"
              >
          </div>
        </div>
      </div>`;
  });

  describe("addTag", () => {
    beforeEach(() => {
      variant_add_tag.value = "new_tag";
      variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
    });

    it("updates the hidden input tag list", () => {
      expect(variant_tag_list.value).toBe("tag 1,tag 2,tag 3,new_tag");
    });

    it("adds the new tag to the HTML tag list", () => {
      const tagList = document.getElementsByClassName("tag-list")[0];

      // 1 template + 3 tags + 1 new tag
      expect(tagList.childElementCount).toBe(5);
    });

    it("clears the tag input", () => {
      expect(variant_add_tag.value).toBe("");
    });

    describe("with an empty new tag", () => {
      it("doesn't add the tag", () => {
        variant_add_tag.value = " ";
        variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));

        const tagList = document.getElementsByClassName("tag-list")[0];

        // 1 template + 3 tags + new tag (added in the beforeEach)
        expect(tagList.childElementCount).toBe(5);
      });
    });

    describe("when tag already exist", () => {
      beforeEach(() => {
        // Trying to add an existing tag
        variant_add_tag.value = "tag 2";
        variant_add_tag.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
      });

      it("doesn't add the tag", () => {
        const tagList = document.getElementsByClassName("tag-list")[0];

        // 1 template + 4 tags
        expect(tagList.childElementCount).toBe(5);
        expect(variant_add_tag.value).toBe("tag 2");
      });

      it("highlights the new tag name in red", () => {
        expect(variant_add_tag.classList).toContain("tag-error");
      });
    });
  });

  describe("removeTag", () => {
    beforeEach(() => {
      const removeButtons = document.getElementsByClassName("remove-button");
      // Click on tag 2
      removeButtons[1].click();
    });

    it("updates the hidden input tag list", () => {
      expect(variant_tag_list.value).toBe("tag 1,tag 3");
    });

    it("removes the tag from the HTML tag list", () => {
      const tagList = document.getElementsByClassName("tag-list")[0];
      // 1 template + 2 tags
      expect(tagList.childElementCount).toBe(3);
    });
  });

  describe("filterInput", () => {
    it("removes comma from the tag input", () => {
      variant_add_tag.value = "text";
      variant_add_tag.dispatchEvent(new KeyboardEvent("keyup", { key: "," }));

      expect(variant_add_tag.value).toBe("text");
    });

    it("removes error highlight", () => {
      variant_add_tag.value = "text";
      variant_add_tag.classList.add("tag-error");

      variant_add_tag.dispatchEvent(new KeyboardEvent("keyup", { key: "a" }));

      expect(variant_add_tag.classList).not.toContain("tag-error");
    });
  });
});

/*
 * This source file is part of RmlUi, the HTML/CSS Interface Middleware
 *
 * For the latest information, see http://github.com/mikke89/RmlUi
 *
 * Copyright (c) 2008-2010 CodePoint Ltd, Shift Technology Ltd
 * Copyright (c) 2019 The RmlUi Team, and contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#ifndef RMLUI_CORE_ELEMENTSTYLE_H
#define RMLUI_CORE_ELEMENTSTYLE_H

#include "../Include/RmlUi/ComputedValues.h"
#include "../Include/RmlUi/Types.h"
#include "../Include/RmlUi/PropertyIdSet.h"
#include "../Include/RmlUi/PropertyDictionary.h"

namespace Rml {

class ElementDefinition;
class PropertiesIterator;

/**
	Manages an element's style and property information.
	@author Lloyd Weehuizen
 */

class ElementStyle
{
public:
	/// Constructor
	/// @param[in] element The element this structure belongs to.
	ElementStyle(Element* element);
	
	/// Update this definition if required
	void UpdateDefinition();

	void SetPseudoClass(PseudoClass pseudo_class, bool activate);
	bool IsPseudoClassSet(PseudoClassSet pseudo_class) const;
	PseudoClassSet GetActivePseudoClasses() const;

	/// Sets or removes a class on the element.
	/// @param[in] class_name The name of the class to add or remove from the class list.
	/// @param[in] activate True if the class is to be added, false to be removed.
	void SetClass(const std::string& class_name, bool activate);
	/// Checks if a class is set on the element.
	/// @param[in] class_name The name of the class to check for.
	/// @return True if the class is set on the element, false otherwise.
	bool IsClassSet(const std::string& class_name) const;
	/// Specifies the entire list of classes for this element. This will replace any others specified.
	/// @param[in] class_names The list of class names to set on the style, separated by spaces.
	void SetClassNames(const std::string& class_names);
	/// Return the active class list.
	/// @return A string containing all the classes on the element, separated by spaces.
	std::string GetClassNames() const;

	/// Sets a local property override on the element to a pre-parsed value.
	/// @param[in] name The name of the new property.
	/// @param[in] property The parsed property to set.
	bool SetProperty(PropertyId id, const Property& property);
	bool SetPropertyImmediate(PropertyId id, const Property& property);
	/// Removes a local property override on the element; its value will revert to that defined in
	/// the style sheet.
	/// @param[in] name The name of the local property definition to remove.
	void RemoveProperty(PropertyId id);
	/// Returns one of this element's properties. If this element is not defined this property, or a parent cannot
	/// be found that we can inherit the property from, the default value will be returned.
	/// @param[in] name The name of the property to fetch the value for.
	/// @return The value of this property for this element, or nullptr if no property exists with the given name.
	const Property* GetProperty(PropertyId id) const;
	/// Returns one of this element's properties. If this element is not defined this property, nullptr will be
	/// returned.
	/// @param[in] name The name of the property to fetch the value for.
	/// @return The value of this property for this element, or nullptr if this property has not been explicitly defined for this element.
	const Property* GetLocalProperty(PropertyId id) const;

	/// Mark definition and all children dirty.
	void DirtyDefinition();

	/// Mark inherited properties dirty.
	/// Inherited properties will automatically be set when parent inherited properties are changed. However,
	/// some operations may require to dirty these manually, such as when moving an element into another.
	void DirtyInheritedProperties();

	/// Dirties all properties with a given unit on the current element and recursively on all children.
	void DirtyPropertiesWithUnitRecursive(Property::Unit unit);

	/// Returns true if any properties are dirty such that computed values need to be recomputed
	bool AnyPropertiesDirty() const;

	/// Turns the local and inherited properties into computed values for this element. These values can in turn be used during the layout procedure.
	/// Must be called in correct order, always parent before its children.
	PropertyIdSet ComputeValues(Style::ComputedValues& values);

	/// Returns an iterator for iterating the local properties of this element.
	/// Note: Modifying the element's style invalidates its iterator.
	PropertiesIterator Iterate() const;

private:
	// Dirty all child definitions
	void DirtyChildDefinitions();
	// Sets a single property as dirty.
	void DirtyProperty(PropertyId id);
	// Sets a list of properties as dirty.
	void DirtyProperties(const PropertyIdSet& properties);

	const Property* GetPropertyByDefinition(PropertyId id, const ElementDefinition* definition) const;
	void TransitionPropertyChanges(PropertyIdSet & properties, const ElementDefinition * new_definition);
	bool TransitionPropertyChanges(PropertyId id, const Property& property);

	// Element these properties belong to
	Element* element;

	// The list of classes applicable to this object.
	std::vector<std::string> classes;
	// This element's current pseudo-classes.
	PseudoClassSet pseudo_classes = 0;

	// Any properties that have been overridden in this element.
	PropertyDictionary inline_properties;
	// The definition of this element, provides applicable properties from the stylesheet.
	std::shared_ptr<ElementDefinition> definition;
	// Set if a new element definition should be fetched from the style.
	bool definition_dirty;

	PropertyIdSet dirty_properties;
};

float ComputeProperty(FloatValue value, Element* e);
float ComputePropertyW(FloatValue value, Element* e);
float ComputePropertyH(FloatValue value, Element* e);
float ComputeProperty(const Property* property, Element* e);
float ComputePropertyW(const Property* property, Element* e);
float ComputePropertyH(const Property* property, Element* e);

} // namespace Rml
#endif

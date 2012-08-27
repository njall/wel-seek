require 'test_helper'

class OrganismTest < ActiveSupport::TestCase
  
  fixtures :organisms,:experiments,:models,:bioportal_concepts,:experiment_organisms,:studies

  test "experiment association" do
    o=organisms(:Saccharomyces_cerevisiae)
    a=experiments(:metabolomics_experiment)
    assert_equal 1,o.experiments.size
    assert o.experiments.include?(a)
  end

  test "searchable_terms" do
    o=organisms(:Saccharomyces_cerevisiae)
    assert o.searchable_terms.include?("Saccharomyces cerevisiae")
  end
 
  test "bioportal_link" do
    o=organisms(:yeast_with_bioportal_concept)
    assert_not_nil o.bioportal_concept,"There should be an associated bioportal concept"
    assert_equal 1132,o.ontology_id
    assert_equal 38802,o.ontology_version_id
    assert_equal "NCBITaxon:4932",o.concept_uri    
  end

  test "assigning terms to organism with no concept by default" do
    o=organisms(:Saccharomyces_cerevisiae)
    assert_equal nil,o.ontology_id
    assert_equal nil,o.ontology_version_id
    assert_equal nil,o.concept_uri
    o.ontology_id=4
    o.ontology_version_id=5
    o.concept_uri="abc"
    o.save!
    o=Organism.find(o.id)
    assert_equal 4,o.ontology_id
    assert_equal 5,o.ontology_version_id
    assert_equal "abc",o.concept_uri
  end

  test "dependent destroyed" do
    o=organisms(:yeast_with_bioportal_concept)
    concept=o.bioportal_concept
    assert_not_nil BioportalConcept.find_by_id(concept.id)
    o.destroy
    assert_nil BioportalConcept.find_by_id(concept.id)
  end
  
  test "can_delete?" do
    o=organisms(:yeast)
    assert !o.can_delete?
    o=organisms(:human)
    assert o.can_delete?
    o=organisms(:organism_linked_project_only)
    assert !o.can_delete?
  end

#  test "get concept" do
#    o=organisms(:yeast_with_bioportal_concept)
#    concept=o.concept({:maxchildren=>5,:light=>0,:refresh=>true})
#    assert_not_nil concept
#    assert_equal "NCBITaxon:4932",concept[:id]
#    assert !concept[:synonyms].empty?
#    assert !concept[:children].empty?
#    assert !concept[:parents].empty?
#    assert_equal 38802,concept[:ontology_version_id]
#  end

#  test "get ontology" do
#    o=organisms(:yeast_with_bioportal_concept)
#    ontology=o.ontology({:maxchildren=>5,:light=>0,:refresh=>true})
#    assert_not_nil ontology
#    assert_equal "1132",ontology[:ontology_id]
#  end

end

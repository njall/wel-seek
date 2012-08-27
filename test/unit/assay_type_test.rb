require 'test_helper'

class ExperimentTypeTest < ActiveSupport::TestCase
  fixtures :experiment_types,:experiments

#  test "parent and child" do
#    parent=experiment_types(:parent)
#
#    assert_equal 2,parent.child_experiment_types.size
#    child1=experiment_types(:child1)
#    child2=experiment_types(:child2)
#
#    assert parent.child_experiment_types.include?(child1)
#    assert parent.child_experiment_types.include?(child2)
#
#    assert_equal parent,child1.parent_experiment_type
#    assert_equal parent,child2.parent_experiment_type
#  end

  test "parent and children structure" do
    parent=ExperimentType.new(:title=>"parent")
    c1=ExperimentType.new(:title=>"child1")
    c2=ExperimentType.new(:title=>"child2")
    parent.children << c1
    parent.children << c2
    parent.save
    parent=ExperimentType.find(parent.id)

    assert_equal 2,parent.children.size

    assert_equal c1,parent.children.first
    assert_equal c2,parent.children.last

    assert_equal 1,parent.children.first.parents.size
    assert_equal 1,parent.children.last.parents.size
    
    assert_equal parent,parent.children.first.parents.first
    assert_equal parent,parent.children.last.parents.first

  end

  test "to tree with root" do
    roots = ExperimentType.to_tree(experiment_types(:experimental_experiment_type).id)
    assert_equal 1,roots.size
    assert roots.include?(experiment_types(:experimental_experiment_type))
  end

  test "to tree" do
    roots=ExperimentType.to_tree
    assert_equal 10,roots.size
    assert roots.include?(experiment_types(:metabolomics))
    assert roots.include?(experiment_types(:proteomics))
    assert roots.include?(experiment_types(:parent1))
    assert roots.include?(experiment_types(:parent2))
    assert roots.include?(experiment_types(:experiment_type_with_child))
    assert roots.include?(experiment_types(:experiment_type_with_child_and_experiment))
    assert roots.include?(experiment_types(:experiment_type_with_only_child_experiments))
    assert roots.include?(experiment_types(:new_parent))
    assert roots.include?(experiment_types(:experimental_experiment_type))
    assert roots.include?(experiment_types(:modelling_experiment_type))
  end

  test "two parents" do

    c1=ExperimentType.new(:title=>"Child")
    p1=ExperimentType.new(:title=>"Parent1")
    p2=ExperimentType.new(:title=>"Parent1")

    c1.parents << p1
    c1.parents << p2

    c1.save

    assert_equal 2,c1.parents.size
    assert_equal 1,p1.children.size
    assert_equal 1,p1.children.size

    child=ExperimentType.find(c1.id)
    assert_equal 2,child.parents.size
    assert child.parents.include?(p1)
    assert child.parents.include?(p2)

    parent=ExperimentType.find(p1.id)
    assert_equal 1,parent.children.size
    assert parent.children.include?(c1)

  end

  test "parents not empty" do
    child1=experiment_types(:child1)
    assert !child1.parents.empty?

    assert !ExperimentType.find(child1.id).parents.empty?
  end

  test "parent and child fixtures" do
    
    parent1=experiment_types(:parent1)
    parent2=experiment_types(:parent2)
    child1=experiment_types(:child1)
    child2=experiment_types(:child2)
    child3=experiment_types(:child3)

    assert_equal 3,parent1.children.size
    assert_equal 1,parent2.children.size

    assert_equal 1,child1.parents.size
    assert_equal 1,child2.parents.size
    assert_equal 2,child3.parents.size

  end

  test "has_children" do
    parent=experiment_types(:metabolomics)
    assert !parent.has_children?
    parent=experiment_types(:parent1)
    assert parent.has_children?
  end

  test "has_parents" do
    child=experiment_types(:metabolomics)
    assert !child.has_parents?
    child=experiment_types(:child1)
    assert child.has_parents?
  end

  test "experiments association" do
    a1=experiment_types(:parent1)
    assert a1.experiments.empty?
    a2=experiment_types(:metabolomics)
    assert a2.experiments.include?(experiments(:metabolomics_experiment))
    assert a2.experiments.include?(experiments(:metabolomics_experiment2))
  end
  
  test "get_all_descendants" do
    parent_experiment = ExperimentType.new(:title=>"Parent")
    c1_experiment = ExperimentType.new(:title=>"Child1")
    c2_experiment = ExperimentType.new(:title=>"Child2")
    gc1_experiment = ExperimentType.new(:title=>"GrandChild1")
    
    parent_experiment.children << c1_experiment
    parent_experiment.children << c2_experiment
    c1_experiment.children << gc1_experiment
    
    assert_equal 3,parent_experiment.get_all_descendants.size
  end

  test "experimental experiment type id" do
    assert_not_nil ExperimentType.experimental_experiment_type_id
  end

  test "modelling experiment type id" do
    assert_not_nil ExperimentType.modelling_experiment_type_id
  end

  
end

#ifndef SCREAM_P3_INPUTS_INITIALIZER_HPP
#define SCREAM_P3_INPUTS_INITIALIZER_HPP

#include "share/field/field_initializer.hpp"

namespace scream {

class P3InputsInitializer : public FieldInitializer
{
public:

  virtual ~P3InputsInitializer () = default;

  // The name of the initializer
  std::string name () const { return "P3InputsInitializer"; }

  // Initialize fields
  void initialize_fields ();

  const std::set<FieldIdentifier>& get_inited_fields () const {
    return m_fields_id;
  }

protected:

  void add_field (const field_type& f);
  void add_field (const field_type& f, const field_type& f_ref,
                  const remapper_ptr_type& remapper);

  std::map<std::string,const field_type>  m_fields;

  std::set<FieldIdentifier> m_fields_id;

  std::shared_ptr<AbstractRemapper<Real>> m_remapper;
};

} // namespace scream

#endif // SCREAM_P3_INPUTS_INITIALIZER_HPP

import { createConsumer } from "@rails/actioncable"

// One Action Cable connection per page, authenticated by the session cookie.
export default createConsumer()
